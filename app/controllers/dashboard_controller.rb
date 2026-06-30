class DashboardController < ApplicationController
  def index
    DueSnapshotEnqueuer.new.enqueue_due!

    @trade_date = selected_trade_date
    @snapshot_type = selected_snapshot_type
    @snapshot = MarketSnapshot.find_by(trade_date: @trade_date, snapshot_type: @snapshot_type)
    @groups = DashboardBuilder.new(@snapshot).groups
    @global_asset_groups = global_asset_groups
    @available_dates = MarketSnapshot.select(:trade_date).distinct.order(trade_date: :desc).pluck(:trade_date)
    @sectors = [ Sector.unassigned ] + Sector.named.to_a
  end

  private

  def global_asset_groups
    records = GlobalAssetSnapshot.for_snapshot(@trade_date, @snapshot_type).display_order
    GlobalAssets::Registry.display_groups(records)
  end

  def selected_trade_date
    return Date.parse(params[:trade_date]) if params[:trade_date].present?

    MarketSnapshot.maximum(:trade_date) || Date.current
  rescue ArgumentError
    Date.current
  end

  def selected_snapshot_type
    return params[:snapshot_type] if MarketSnapshot::SNAPSHOT_TYPES.key?(params[:snapshot_type])

    "intraday"
  end
end
