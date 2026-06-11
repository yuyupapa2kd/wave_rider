require "test_helper"

class LeaderSelectionTest < ActiveSupport::TestCase
  test "keeps one leader per snapshot sector" do
    sector = Sector.create!(name: "반도체")
    stock_a = Stock.create!(ticker: "005930", name: "삼성전자")
    stock_b = Stock.create!(ticker: "000660", name: "SK하이닉스")
    snapshot = MarketSnapshot.create!(trade_date: Date.new(2026, 6, 5), snapshot_type: "intraday")

    LeaderSelection.select!(market_snapshot: snapshot, sector: sector, stock: stock_a)
    LeaderSelection.select!(market_snapshot: snapshot, sector: sector, stock: stock_b)

    assert_equal [ stock_b.id ], LeaderSelection.where(market_snapshot: snapshot, sector: sector).pluck(:stock_id)
  end

  test "sector assignment clears later leader selections for changed stock" do
    old_sector = Sector.create!(name: "미디어")
    new_sector = Sector.create!(name: "게임")
    stock = Stock.create!(ticker: "035420", name: "NAVER")
    snapshot = MarketSnapshot.create!(trade_date: Date.new(2026, 6, 5), snapshot_type: "closing")

    stock.assign_sector!(sector: old_sector, effective_on: Date.new(2026, 6, 5))
    LeaderSelection.select!(market_snapshot: snapshot, sector: old_sector, stock: stock)

    stock.assign_sector!(sector: new_sector, effective_on: Date.new(2026, 6, 5))

    assert_empty LeaderSelection.where(stock: stock)
  end
end
