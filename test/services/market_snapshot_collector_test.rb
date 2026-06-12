require "test_helper"

class MarketSnapshotCollectorTest < ActiveSupport::TestCase
  class FailingClient
    def trading_day?(_date)
      true
    end

    def top_volume_candidates
      raise Kiwoom::ApiError.new("API 실패", endpoint: "/test")
    end
  end

  class PartialMetricsClient
    def trading_day?(_date)
      true
    end

    def top_volume_candidates
      [
        { ticker: "000001", name: "부족종목", trade_value: 100_000_000_000, volume: 1, current_price: 1_000, change_rate: 1, raw_payload: {} },
        { ticker: "000002", name: "정상종목", trade_value: 100_000_000_000, volume: 1, current_price: 1_000, change_rate: 1, raw_payload: {} }
      ]
    end

    def investor_flows(_ticker, trade_date)
      10.times.map do |index|
        date = trade_date - index.days
        { date: date, institution: 1, pension: 2, foreign: 3, individual: 4, raw_payload: {} }
      end
    end

    def daily_execution_strength(ticker)
      return [] if ticker == "000001"

      10.times.map do |index|
        date = Date.new(2026, 6, 5) - index.days
        { date: date, execution_strength: 100, raw_payload: {} }
      end
    end
  end

  class TopHundredClient
    def trading_day?(_date)
      true
    end

    def top_volume_candidates
      101.times.map do |index|
        {
          ticker: "%06d" % index,
          name: "종목#{index}",
          trade_value: index == 99 ? 100_000_000_000 : 101 - index,
          volume: 101 - index,
          current_price: 1_000,
          change_rate: if index == 0
                         10
                       elsif index == 99
                         9.99
                       else
                         12
                       end,
          raw_payload: {}
        }
      end
    end

    def investor_flows(_ticker, trade_date)
      metric_rows(trade_date).map do |date|
        { date: date, institution: 1, pension: 2, foreign: 3, individual: 4, raw_payload: {} }
      end
    end

    def daily_execution_strength(_ticker)
      metric_rows(Date.new(2026, 6, 5)).map do |date|
        { date: date, execution_strength: 100, raw_payload: {} }
      end
    end

    private

    def metric_rows(trade_date)
      10.times.map { |index| trade_date - index.days }
    end
  end

  test "keeps existing successful data when recollection fails" do
    snapshot = MarketSnapshot.create!(trade_date: Date.new(2026, 6, 5), snapshot_type: "intraday", status: "success")
    stock = Stock.create!(ticker: "005930", name: "삼성전자")
    snapshot.snapshot_items.create!(stock: stock, trade_value: 1, change_rate: 1, volume: 1, current_price: 1_000)

    assert_raises(Kiwoom::ApiError) do
      MarketSnapshotCollector.new(client: FailingClient.new).collect!(trade_date: snapshot.trade_date, snapshot_type: snapshot.snapshot_type)
    end

    snapshot.reload
    assert_equal "failed", snapshot.status
    assert_equal 1, snapshot.snapshot_items.count
  end

  test "skips candidates with insufficient metric history" do
    snapshot = MarketSnapshotCollector.new(client: PartialMetricsClient.new).collect!(
      trade_date: Date.new(2026, 6, 5),
      snapshot_type: "intraday"
    )

    tickers = snapshot.snapshot_items.joins(:stock).pluck("stocks.ticker")

    assert_equal "success", snapshot.status
    assert_equal [ "000002" ], tickers
    assert_equal 1, snapshot.collection_logs.where(level: "warn", stage: "metrics").count
  end

  test "keeps candidates with trade value over 100 billion won or change rate over 10 percent" do
    snapshot = MarketSnapshotCollector.new(client: TopHundredClient.new).collect!(
      trade_date: Date.new(2026, 6, 5),
      snapshot_type: "intraday"
    )

    tickers = snapshot.snapshot_items.joins(:stock).pluck("stocks.ticker")

    assert_equal "success", snapshot.status
    assert_equal 100, tickers.size
    assert_includes tickers, "000099"
    assert_not_includes tickers, "000100"
    assert_includes tickers, "000000"
  end
end
