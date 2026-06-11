require "test_helper"

class DashboardBuilderTest < ActiveSupport::TestCase
  test "sorts sectors by total trade value and keeps unassigned last" do
    chip = Sector.create!(name: "반도체")
    bio = Sector.create!(name: "바이오")
    assigned_stock = Stock.create!(ticker: "000001", name: "A")
    high_stock = Stock.create!(ticker: "000002", name: "B")
    unassigned_stock = Stock.create!(ticker: "000003", name: "C")
    snapshot = MarketSnapshot.create!(trade_date: Date.new(2026, 6, 5), snapshot_type: "intraday")

    assigned_stock.assign_sector!(sector: chip, effective_on: snapshot.trade_date)
    high_stock.assign_sector!(sector: bio, effective_on: snapshot.trade_date)

    snapshot.snapshot_items.create!(stock: assigned_stock, trade_value: 10, change_rate: 1, volume: 1, current_price: 1_000)
    snapshot.snapshot_items.create!(stock: high_stock, trade_value: 20, change_rate: 1, volume: 1, current_price: 1_000)
    snapshot.snapshot_items.create!(stock: unassigned_stock, trade_value: 100, change_rate: 1, volume: 1, current_price: 1_000)

    names = DashboardBuilder.new(snapshot).groups.map { |group| group.sector.name }

    assert_equal [ "바이오", "반도체", "미지정" ], names
  end
end
