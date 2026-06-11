require "test_helper"

class MarketSnapshotTest < ActiveSupport::TestCase
  test "allows intraday and closing snapshots on the same trade date" do
    trade_date = Date.new(2026, 6, 5)

    MarketSnapshot.create!(trade_date: trade_date, snapshot_type: "intraday")
    MarketSnapshot.create!(trade_date: trade_date, snapshot_type: "closing")

    assert_equal 2, MarketSnapshot.where(trade_date: trade_date).count
  end
end
