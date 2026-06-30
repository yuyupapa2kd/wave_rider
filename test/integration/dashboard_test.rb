require "test_helper"

class DashboardTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  test "renders recollection confirmation and stock details collapsed" do
    login
    sector = Sector.create!(name: "반도체")
    stock = Stock.create!(ticker: "005930", name: "삼성전자")
    stock.assign_sector!(sector: sector, effective_on: Date.new(2026, 6, 5))
    snapshot = MarketSnapshot.create!(trade_date: Date.new(2026, 6, 5), snapshot_type: "intraday", status: "success")
    item = snapshot.snapshot_items.create!(stock: stock, trade_value: 100_000_000_000, change_rate: 3.2, volume: 1_000, current_price: 70_000)
    item.daily_metrics.create!(metric_date: snapshot.trade_date, institution_net_purchase: 1, pension_net_purchase: 2, foreign_net_purchase: 3, individual_net_purchase: 4, execution_strength: 110)

    get root_path(trade_date: snapshot.trade_date, snapshot_type: snapshot.snapshot_type)

    assert_response :success
    assert_select "[data-turbo-confirm]"
    assert_select "details.metric-details"
    assert_includes response.body, "삼성전자"
  end

  test "renders sector preview with assigned sectors ordered by trade value" do
    login
    trade_date = Date.new(2026, 6, 5)
    chip = Sector.create!(name: "반도체")
    bio = Sector.create!(name: "바이오")
    game = Sector.create!(name: "게임")
    car = Sector.create!(name: "자동차")
    chip_stock_a = Stock.create!(ticker: "000001", name: "반도체A")
    chip_stock_b = Stock.create!(ticker: "000002", name: "반도체B")
    bio_stock = Stock.create!(ticker: "000003", name: "바이오A")
    game_stock = Stock.create!(ticker: "000004", name: "게임A")
    car_stock = Stock.create!(ticker: "000005", name: "자동차A")
    unassigned_stock = Stock.create!(ticker: "000006", name: "미지정A")
    snapshot = MarketSnapshot.create!(trade_date: trade_date, snapshot_type: "intraday", status: "success")

    chip_stock_a.assign_sector!(sector: chip, effective_on: trade_date)
    chip_stock_b.assign_sector!(sector: chip, effective_on: trade_date)
    bio_stock.assign_sector!(sector: bio, effective_on: trade_date)
    game_stock.assign_sector!(sector: game, effective_on: trade_date)
    car_stock.assign_sector!(sector: car, effective_on: trade_date)

    snapshot.snapshot_items.create!(stock: chip_stock_a, trade_value: 10_000_000_000, change_rate: 4, volume: 1, current_price: 1_000)
    snapshot.snapshot_items.create!(stock: chip_stock_b, trade_value: 5_000_000_000, change_rate: 4, volume: 1, current_price: 1_000)
    snapshot.snapshot_items.create!(stock: bio_stock, trade_value: 20_000_000_000, change_rate: -3, volume: 1, current_price: 1_000)
    snapshot.snapshot_items.create!(stock: game_stock, trade_value: 8_000_000_000, change_rate: 2, volume: 1, current_price: 1_000)
    snapshot.snapshot_items.create!(stock: car_stock, trade_value: 6_000_000_000, change_rate: -1, volume: 1, current_price: 1_000)
    snapshot.snapshot_items.create!(stock: unassigned_stock, trade_value: 100_000_000_000, change_rate: 10, volume: 1, current_price: 1_000)

    get root_path(trade_date: trade_date, snapshot_type: snapshot.snapshot_type)

    assert_response :success
    assert_select ".toolbar + .global-assets"
    assert_select ".global-assets + .sector-preview"
    rows = css_select(".sector-preview-row")
    assert_equal [ "바이오", "반도체", "게임", "자동차" ], rows.map { |row| row.at_css(".sector-preview-name").text.strip }
    assert_select ".sector-preview-name", text: "미지정", count: 0
    assert_select ".sector-preview-hole"
    assert_select ".sector-preview-center-value", text: "490억"
    assert_equal [ "color: #2563eb;", "color: #dc2626;", "color: #dc2626;", "color: #2563eb;" ], css_select(".sector-preview-change").map { |node| node["style"] }
    assert_select ".sector-preview-slice[stroke='#172026'][stroke-width='0.45']"
    assert_equal [ "바이오", "반도체", "게임", "기타" ], css_select(".sector-preview-label").map { |node| node.text.strip }
    assert_select ".sector-preview-label", text: "자동차", count: 0
  end

  test "renders global assets above sector preview for the selected snapshot" do
    login
    trade_date = Date.new(2026, 6, 5)
    sector = Sector.create!(name: "반도체")
    stock = Stock.create!(ticker: "000010", name: "테스트")
    stock.assign_sector!(sector: sector, effective_on: trade_date)
    snapshot = MarketSnapshot.create!(trade_date: trade_date, snapshot_type: "intraday", status: "success")
    snapshot.snapshot_items.create!(stock: stock, trade_value: 100, change_rate: 1, volume: 1, current_price: 1_000)

    GlobalAssetSnapshot.create!(
      trade_date: trade_date,
      snapshot_type: "intraday",
      category: "indices",
      category_position: 0,
      asset_code: "nasdaq",
      position: 0,
      name: "나스닥",
      price: BigDecimal("100.12"),
      change_value: BigDecimal("1.2"),
      change_rate: BigDecimal("1.23"),
      source: "test",
      source_symbol: "^IXIC",
      captured_at: Time.zone.local(2026, 6, 5, 14, 30),
      raw_payload: {}
    )
    GlobalAssetSnapshot.create!(
      trade_date: trade_date,
      snapshot_type: "intraday",
      category: "commodities",
      category_position: 1,
      asset_code: "wti",
      position: 2,
      name: "WTI",
      price: BigDecimal("70.31"),
      change_value: BigDecimal("-0.2"),
      change_rate: BigDecimal("-0.28"),
      source: "test",
      source_symbol: "CL=F",
      captured_at: Time.zone.local(2026, 6, 5, 14, 30),
      raw_payload: {}
    )

    get root_path(trade_date: trade_date, snapshot_type: "intraday")

    assert_response :success
    assert_select ".toolbar + .global-assets"
    assert_select ".global-assets + .sector-preview"
    assert_select ".global-asset-category h2", text: "지수"
    assert_select ".global-asset-row", text: /나스닥/
    assert_select ".global-asset-price", text: "100.12"
    assert_select ".global-asset-change.is-up", text: "+1.2"
    assert_select ".global-asset-change.is-up", text: "+1.23%"
    assert_select ".global-asset-change.is-down", text: "-0.2"
    assert_select ".global-asset-change.is-down", text: "-0.28%"
  end

  test "renders empty global asset categories when collection data is missing" do
    login
    trade_date = Date.new(2026, 6, 5)
    sector = Sector.create!(name: "반도체")
    stock = Stock.create!(ticker: "000011", name: "테스트2")
    stock.assign_sector!(sector: sector, effective_on: trade_date)
    snapshot = MarketSnapshot.create!(trade_date: trade_date, snapshot_type: "intraday", status: "success")
    snapshot.snapshot_items.create!(stock: stock, trade_value: 100, change_rate: 1, volume: 1, current_price: 1_000)

    get root_path(trade_date: trade_date, snapshot_type: "intraday")

    assert_response :success
    assert_select ".global-assets-empty", count: GlobalAssets::Registry::CATEGORIES.size
  end

  test "enqueues due snapshot before selecting latest date" do
    login
    MarketSnapshot.create!(trade_date: Date.new(2026, 6, 11), snapshot_type: "intraday", status: "success")

    travel_to Time.zone.local(2026, 6, 12, 14, 35) do
      assert_difference -> { MarketSnapshot.where(trade_date: Date.new(2026, 6, 12), snapshot_type: "intraday").count }, 1 do
        get root_path
      end
    end

    assert_response :success
    assert_select "select[name='trade_date'] option", text: "2026-06-12"
    assert_includes response.body, "2026-06-12 14:30 장중"
  end

  private

  def login
    post session_path, params: { username: "admin", password: "change-me" }
  end
end
