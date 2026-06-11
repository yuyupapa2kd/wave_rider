class CollectionsController < ApplicationController
  def create
    trade_date = Date.parse(collection_params.fetch(:trade_date))
    snapshot_type = collection_params.fetch(:snapshot_type)

    snapshot = MarketSnapshot.find_or_create_by!(trade_date: trade_date, snapshot_type: snapshot_type)
    snapshot.update!(status: "collecting", started_at: Time.current, failure_message: nil)
    CollectMarketSnapshotJob.perform_later(snapshot_type, trade_date.to_s)

    redirect_to root_path(trade_date: trade_date, snapshot_type: snapshot_type), notice: "수집을 시작했습니다. 잠시 후 새로고침해 주세요."
  rescue ArgumentError
    redirect_to root_path, alert: "거래일이 올바르지 않습니다."
  end

  private

  def collection_params
    params.permit(:trade_date, :snapshot_type)
  end
end
