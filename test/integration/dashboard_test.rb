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

  test "enqueues due snapshot before selecting latest date" do
    login
    MarketSnapshot.create!(trade_date: Date.new(2026, 6, 11), snapshot_type: "intraday", status: "success")

    travel_to Time.zone.local(2026, 6, 12, 15, 5) do
      assert_difference -> { MarketSnapshot.where(trade_date: Date.new(2026, 6, 12), snapshot_type: "intraday").count }, 1 do
        get root_path
      end
    end

    assert_response :success
    assert_select "select[name='trade_date'] option", text: "2026-06-12"
    assert_includes response.body, "2026-06-12 15:00 장중"
  end

  private

  def login
    post session_path, params: { username: "admin", password: "change-me" }
  end
end
