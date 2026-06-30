require "bigdecimal"
require "cgi"
require "json"
require "net/http"
require "uri"

module GlobalAssets
  class YahooChartClient
    BASE_URL = "https://query1.finance.yahoo.com"

    def initialize(base_url: BASE_URL)
      @base_url = base_url
    end

    def quote(symbol)
      payload = request_chart(symbol)
      result = payload.dig("chart", "result", 0)
      raise "Yahoo chart result missing for #{symbol}" if result.blank?

      price = decimal_from(result.dig("meta", "regularMarketPrice")) || latest_close(result)
      previous_close = decimal_from(result.dig("meta", "chartPreviousClose")) || previous_close(result)
      raise "Yahoo chart price missing for #{symbol}" if price.blank? || previous_close.blank?

      change_value = price - previous_close
      change_rate = previous_close.zero? ? BigDecimal("0") : change_value / previous_close * 100

      {
        price: price,
        change_value: change_value,
        change_rate: change_rate,
        raw_payload: result
      }
    end

    private

    def request_chart(symbol)
      uri = URI.join(@base_url, "/v8/finance/chart/#{CGI.escape(symbol)}")
      uri.query = URI.encode_www_form(range: "5d", interval: "1d")
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "Mozilla/5.0"
      request["Accept"] = "application/json"

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 10) do |http|
        http.request(request)
      end
      raise "Yahoo chart request failed for #{symbol}: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue JSON::ParserError => error
      raise "Yahoo chart JSON parse failed for #{symbol}: #{error.message}"
    end

    def latest_close(result)
      closes = close_values(result)
      closes.last
    end

    def previous_close(result)
      closes = close_values(result)
      closes[-2]
    end

    def close_values(result)
      result.dig("indicators", "quote", 0, "close").to_a.filter_map { |value| decimal_from(value) }
    end

    def decimal_from(value)
      return if value.blank?

      BigDecimal(value.to_s)
    end
  end
end
