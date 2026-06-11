require "test_helper"

class SectorAssignmentServiceTest < ActiveSupport::TestCase
  test "new sector name takes priority over selected sector" do
    stock = Stock.create!(ticker: "005930", name: "삼성전자")
    unassigned = Sector.unassigned

    sector = SectorAssignmentService.new(
      stock: stock,
      sector_id: unassigned.id,
      new_sector_name: "반도체",
      effective_on: Date.new(2026, 6, 11)
    ).call

    assert_equal "반도체", sector.name
    assert_equal "반도체", stock.sector_on(Date.new(2026, 6, 11)).name
  end

  test "selected sector is used when new sector name is blank" do
    stock = Stock.create!(ticker: "000660", name: "SK하이닉스")
    sector = Sector.create!(name: "반도체")

    SectorAssignmentService.new(
      stock: stock,
      sector_id: sector.id,
      new_sector_name: "",
      effective_on: Date.new(2026, 6, 11)
    ).call

    assert_equal sector, stock.sector_on(Date.new(2026, 6, 11))
  end
end
