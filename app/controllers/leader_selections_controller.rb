class LeaderSelectionsController < ApplicationController
  def create
    snapshot = MarketSnapshot.find(params[:market_snapshot_id])
    stock = Stock.find(params[:stock_id])
    sector = stock.sector_on(snapshot.trade_date)

    if params[:checked] == "1"
      LeaderSelection.select!(market_snapshot: snapshot, sector: sector, stock: stock)
    else
      LeaderSelection.unselect!(market_snapshot: snapshot, sector: sector, stock: stock)
    end

    redirect_back fallback_location: root_path(trade_date: snapshot.trade_date, snapshot_type: snapshot.snapshot_type)
  end
end
