require "test_helper"

class StockSectorHistoryTest < ActiveSupport::TestCase
  test "resolves sector by effective date" do
    stock = Stock.create!(ticker: "005930", name: "삼성전자")
    old_sector = Sector.create!(name: "전자")
    new_sector = Sector.create!(name: "반도체")

    stock.assign_sector!(sector: old_sector, effective_on: Date.new(2026, 6, 1))
    stock.assign_sector!(sector: new_sector, effective_on: Date.new(2026, 6, 5))

    assert_equal old_sector, stock.sector_on(Date.new(2026, 6, 4))
    assert_equal new_sector, stock.sector_on(Date.new(2026, 6, 5))
  end
end
