require "test_helper"

class GlobalAssetCollectorTest < ActiveSupport::TestCase
  FakeClient = Struct.new(:quotes) do
    def quote(symbol)
      quotes.fetch(symbol)
    end
  end

  test "stores global assets by trade date and snapshot type" do
    trade_date = Date.new(2026, 6, 30)
    now = Time.zone.local(2026, 6, 30, 14, 30)
    client = FakeClient.new(
      GlobalAssets::Registry.assets.to_h do |asset|
        [
          asset.fetch(:symbol),
          {
            price: BigDecimal("100"),
            change_value: BigDecimal("1.5"),
            change_rate: BigDecimal("1.5"),
            raw_payload: { "symbol" => asset.fetch(:symbol) }
          }
        ]
      end
    )

    assert_difference -> { GlobalAssetSnapshot.count }, GlobalAssets::Registry.assets.size do
      GlobalAssetCollector.new(client: client, now: now).collect!(trade_date: trade_date, snapshot_type: "intraday")
    end

    snapshot = GlobalAssetSnapshot.find_by!(trade_date: trade_date, snapshot_type: "intraday", asset_code: "nasdaq")
    assert_equal "지수", GlobalAssets::Registry.display_groups([ snapshot ]).first.fetch(:label)
    assert_equal BigDecimal("100"), snapshot.price
    assert_equal BigDecimal("1.5"), snapshot.change_value
    assert_equal BigDecimal("1.5"), snapshot.change_rate
    assert_equal "yahoo_chart", snapshot.source
    assert_equal "^IXIC", snapshot.source_symbol
    assert_equal now, snapshot.captured_at
  end

  test "keeps snapshot types separate for the same date and asset" do
    trade_date = Date.new(2026, 6, 30)
    client = FakeClient.new(
      GlobalAssets::Registry.assets.to_h do |asset|
        [
          asset.fetch(:symbol),
          {
            price: BigDecimal("100"),
            change_value: BigDecimal("1"),
            change_rate: BigDecimal("1"),
            raw_payload: {}
          }
        ]
      end
    )

    collector = GlobalAssetCollector.new(client: client)

    assert_difference -> { GlobalAssetSnapshot.where(trade_date: trade_date, asset_code: "nasdaq").count }, 2 do
      collector.collect!(trade_date: trade_date, snapshot_type: "intraday")
      collector.collect!(trade_date: trade_date, snapshot_type: "closing")
    end
  end

  test "skips failed asset quotes without raising" do
    failing_client = Class.new do
      def quote(_symbol)
        raise "network failure"
      end
    end.new

    assert_nothing_raised do
      result = GlobalAssetCollector.new(client: failing_client).collect!(
        trade_date: Date.new(2026, 6, 30),
        snapshot_type: "intraday"
      )
      assert_empty result
    end
  end
end
