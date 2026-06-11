require "test_helper"

class KiwoomClientTest < ActiveSupport::TestCase
  test "top volume candidates sends Kiwoom guide body" do
    client = Kiwoom::Client.new(app_key: "app-key", secret_key: "secret-key")
    request = capture_post(client, response: { "tdy_trde_qty_upper" => [] }) do
      client.top_volume_candidates
    end

    assert_equal "/api/dostk/rkinfo", request.fetch(:endpoint)
    assert_equal "ka10030", request.fetch(:api_id)
    assert_equal(
      {
        mrkt_tp: "000",
        sort_tp: "1",
        mang_stk_incls: "16",
        crd_tp: "0",
        trde_qty_tp: "0",
        pric_tp: "0",
        trde_prica_tp: "0",
        mrkt_open_tp: "0",
        stex_tp: "3"
      },
      request.fetch(:body)
    )
  end

  test "top volume candidates excludes domestic ETF style names" do
    client = Kiwoom::Client.new(app_key: "app-key", secret_key: "secret-key")
    response = {
      "tdy_trde_qty_upper" => [
        {
          "stk_cd" => "A0193T0",
          "stk_nm" => "KODEX SK하이닉스단일종목레버리지",
          "cur_prc" => "29895",
          "trde_qty" => "91331237",
          "trde_amt" => "2747100",
          "flu_rt" => "+3.19"
        },
        {
          "stk_cd" => "A005930",
          "stk_nm" => "삼성전자",
          "cur_prc" => "70000",
          "trde_qty" => "1000000",
          "trde_amt" => "700000",
          "flu_rt" => "+1.23"
        }
      ]
    }

    result = capture_post(client, response: response) do
      client.top_volume_candidates
    end

    assert_equal [ "005930" ], result.map { |candidate| candidate.fetch(:ticker) }
  end

  test "top volume candidates stores trade amount in won" do
    client = Kiwoom::Client.new(app_key: "app-key", secret_key: "secret-key")
    response = {
      "tdy_trde_qty_upper" => [
        {
          "stk_cd" => "A000660",
          "stk_nm" => "SK하이닉스",
          "cur_prc" => "220800",
          "trde_qty" => "9180653",
          "trde_amt" => "7615763",
          "flu_rt" => "+15.54"
        }
      ]
    }

    result = capture_post(client, response: response) do
      client.top_volume_candidates
    end

    assert_equal 7_615_763_000_000, result.first.fetch(:trade_value)
  end

  test "investor flows sends dt based body" do
    client = Kiwoom::Client.new(app_key: "app-key", secret_key: "secret-key")
    request = capture_post(client, response: { "stk_invsr_orgn_chart" => [] }) do
      client.investor_flows("005930", Date.new(2026, 6, 5))
    end

    assert_equal "/api/dostk/chart", request.fetch(:endpoint)
    assert_equal "ka10060", request.fetch(:api_id)
    assert_equal(
      { dt: "20260605", stk_cd: "005930", amt_qty_tp: "1", trde_tp: "0", unit_tp: "1" },
      request.fetch(:body)
    )
  end

  test "daily execution strength sends stock code only" do
    client = Kiwoom::Client.new(app_key: "app-key", secret_key: "secret-key")
    request = nil
    rows = capture_post(
      client,
      response: { "cntr_str_daly" => [ { "dt" => "20260605", "cntr_str" => "123.45" } ] },
      request_store: ->(captured) { request = captured }
    ) do
      client.daily_execution_strength("005930")
    end

    assert_equal "/api/dostk/mrkcond", request.fetch(:endpoint)
    assert_equal "ka10047", request.fetch(:api_id)
    assert_equal({ stk_cd: "005930" }, request.fetch(:body))
    assert_equal Date.new(2026, 6, 5), rows.first.fetch(:date)
    assert_equal BigDecimal("123.45"), rows.first.fetch(:execution_strength)
  end

  private

  def capture_post(client, response:, request_store: nil)
    captured_request = nil
    client.define_singleton_method(:post) do |endpoint, api_id, body, **_kwargs|
      captured_request = { endpoint: endpoint, api_id: api_id, body: body }
      response
    end

    result = yield
    request_store&.call(captured_request)
    request_store || result.present? ? result : captured_request
  end
end
