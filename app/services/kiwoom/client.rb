require "net/http"
require "json"
require "bigdecimal/util"

module Kiwoom
  class Client
    TOKEN_PATH = "/oauth2/token"
    REAL_BASE_URL = "https://api.kiwoom.com"

    attr_reader :last_response_headers

    def initialize(
      app_key: ENV.fetch("KIWOOM_APP_KEY", nil),
      secret_key: ENV.fetch("KIWOOM_SECRET_KEY", nil),
      base_url: ENV.fetch("KIWOOM_API_BASE_URL", REAL_BASE_URL),
      request_delay: ENV.fetch("KIWOOM_REQUEST_DELAY", "0.2").to_f
    )
      @app_key = app_key
      @secret_key = secret_key
      @base_url = base_url
      @request_delay = request_delay
      @token = nil
      @token_expires_at = nil
      @last_request_at = nil
      @last_response_headers = {}
    end

    def trading_day?(date)
      rows = daily_chart(ENV.fetch("KIWOOM_MARKET_CHECK_TICKER", "005930"), date)
      latest = rows.map { |row| parse_date(row["dt"] || row["date"]) }.compact.max
      latest == date
    end

    def top_volume_candidates
      body = {
        mrkt_tp: "000",
        sort_tp: "1",
        mang_stk_incls: "16",
        crd_tp: "0",
        trde_qty_tp: "0",
        pric_tp: "0",
        trde_prica_tp: "0",
        mrkt_open_tp: "0",
        stex_tp: "3"
      }

      response = post("/api/dostk/rkinfo", "ka10030", body)
      rows = response.fetch("tdy_trde_qty_upper") { first_array(response) }
      rows.map { |row| normalize_candidate(row) }.compact
    end

    def investor_flows(ticker, trade_date)
      response = post(
        "/api/dostk/chart",
        "ka10060",
        {
          dt: trade_date.strftime("%Y%m%d"),
          stk_cd: ticker,
          amt_qty_tp: "1",
          trde_tp: "0",
          unit_tp: ENV.fetch("KIWOOM_INVESTOR_UNIT", "1")
        }
      )

      rows = response.fetch("stk_invsr_orgn_chart") { first_array(response) }
      rows.map { |row| normalize_investor_row(row) }.compact
    end

    def daily_execution_strength(ticker)
      response = post(
        "/api/dostk/mrkcond",
        "ka10047",
        { stk_cd: ticker }
      )
      rows = response.fetch("cntr_str_daly") { first_array(response) }
      rows.map { |row| normalize_strength_row(row) }.compact
    end

    def daily_chart(ticker, base_date)
      response = post(
        "/api/dostk/chart",
        "ka10081",
        { stk_cd: ticker, base_dt: base_date.strftime("%Y%m%d"), upd_stkpc_tp: "1" }
      )

      response.fetch("stk_dt_pole_chart_qry") { first_array(response) }
    end

    def post(endpoint, api_id, body, cont_yn: "N", next_key: "", refreshed: false)
      ensure_token!
      throttle!

      response = request_json(
        endpoint,
        body,
        headers: {
          "authorization" => "Bearer #{@token}",
          "api-id" => api_id,
          "cont-yn" => cont_yn,
          "next-key" => next_key
        }
      )
      verify_response!(response, endpoint: endpoint, api_id: api_id)
    rescue ApiError => error
      if token_expired_error?(error) && !refreshed
        @token = nil
        @token_expires_at = nil
        return post(endpoint, api_id, body, cont_yn: cont_yn, next_key: next_key, refreshed: true)
      end

      raise
    end

    private

    def ensure_token!
      return if @token.present? && @token_expires_at.present? && @token_expires_at.future?

      raise ApiError.new("키움 API 키가 설정되지 않았습니다", endpoint: TOKEN_PATH) if @app_key.blank? || @secret_key.blank?

      response = request_json(
        TOKEN_PATH,
        { grant_type: "client_credentials", appkey: @app_key, secretkey: @secret_key },
        headers: {}
      )
      verify_response!(response, endpoint: TOKEN_PATH)

      @token = response.fetch("token")
      @token_expires_at = parse_token_expiry(response["expires_dt"])
    end

    def request_json(endpoint, body, headers:)
      uri = URI.join(@base_url, endpoint)
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json;charset=UTF-8"
      headers.each { |key, value| request[key] = value if value.present? }
      request.body = JSON.generate(body.transform_keys(&:to_s))

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      response = http.request(request)
      @last_response_headers = response.each_header.to_h

      parsed = JSON.parse(response.body.presence || "{}")
      unless response.is_a?(Net::HTTPSuccess)
        raise ApiError.new(
          parsed["return_msg"].presence || parsed["returnMsg"].presence || response.message,
          endpoint: endpoint,
          api_id: headers["api-id"],
          response_code: response.code.to_i,
          body: parsed
        )
      end

      parsed
    rescue JSON::ParserError => error
      raise ApiError.new("키움 API 응답 JSON 파싱 실패: #{error.message}", endpoint: endpoint, api_id: headers["api-id"])
    end

    def verify_response!(response, endpoint:, api_id: nil)
      code = response["return_code"] || response["returnCode"]
      return response if code.nil? || code.to_i.zero?

      raise ApiError.new(
        response["return_msg"].presence || response["returnMsg"].presence || "키움 API 오류",
        endpoint: endpoint,
        api_id: api_id,
        response_code: code.to_i,
        body: response
      )
    end

    def token_expired_error?(error)
      error.response_code.in?([ 401, 403 ])
    end

    def throttle!
      return if @request_delay <= 0 || @last_request_at.nil?

      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - @last_request_at
      sleep(@request_delay - elapsed) if elapsed < @request_delay
    ensure
      @last_request_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def normalize_candidate(row)
      candidate = {
        ticker: clean_ticker(row["stk_cd"]),
        name: row["stk_nm"].to_s.strip,
        current_price: parse_integer(row["cur_prc"]),
        volume: parse_integer(row["trde_qty"]),
        trade_value: parse_trade_value(row),
        change_rate: parse_decimal(row["flu_rt"]),
        raw_payload: row
      }

      return if candidate[:ticker].blank? || candidate[:name].blank?
      return if excluded_candidate?(candidate, row)
      return if candidate[:current_price] < 1_000

      candidate
    end

    def normalize_investor_row(row)
      date = parse_date(row["dt"] || row["date"])
      return if date.nil?

      {
        date: date,
        institution: parse_signed_integer(row["orgn"]),
        pension: parse_signed_integer(row["penfnd_etc"]),
        foreign: parse_signed_integer(row["frgnr_invsr"]),
        individual: parse_signed_integer(row["ind_invsr"]),
        raw_payload: row
      }
    end

    def normalize_strength_row(row)
      date = parse_date(row["dt"] || row["date"])
      return if date.nil?

      {
        date: date,
        execution_strength: parse_decimal(row["cntr_str"]),
        raw_payload: row
      }
    end

    def excluded_candidate?(candidate, row)
      text = ([ candidate[:name] ] + row.values.map(&:to_s)).join(" ")
      return true if text.match?(/ETF|ETN|ELW|스팩|SPAC|관리종목|거래정지|투자경고|투자위험/i)
      return true if text.match?(/KODEX|TIGER|ACE|RISE|SOL|HANARO|KOSEF|ARIRANG|TIMEFOLIO|PLUS/i)
      return true if text.match?(/레버리지|인버스|선물|TR\b|액티브|커버드콜/i)
      return true if candidate[:name].match?(/우$|우B$|우C$|우선주/)

      false
    end

    def first_array(response)
      response.each_value.find { |value| value.is_a?(Array) } || []
    end

    def clean_ticker(value)
      value.to_s.delete_prefix("A").split("_").first.strip
    end

    def parse_integer(value)
      value.to_s.gsub(/[^\d-]/, "").to_i.abs
    end

    def parse_trade_value(row)
      parse_integer(row["trde_amt"] || row["trde_prica"] || row["acc_trde_prica"]) * 1_000_000
    end

    def parse_signed_integer(value)
      cleaned = value.to_s.gsub(/[^0-9+\-]/, "")
      sign = cleaned.start_with?("-") || cleaned.start_with?("--") ? -1 : 1
      sign * cleaned.gsub(/[^\d]/, "").to_i
    end

    def parse_decimal(value)
      value.to_s.gsub(/[^\d\-.]/, "").to_d
    end

    def parse_date(value)
      Date.strptime(value.to_s, "%Y%m%d")
    rescue ArgumentError
      nil
    end

    def parse_token_expiry(value)
      Time.zone.strptime(value.to_s, "%Y%m%d%H%M%S") - 5.minutes
    rescue ArgumentError
      23.hours.from_now
    end
  end
end
