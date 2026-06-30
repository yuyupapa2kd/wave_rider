class CollectMarketSnapshotJob < ApplicationJob
  queue_as :default

  discard_on StandardError

  def perform(snapshot_type, trade_date = Date.current.to_s)
    parsed_trade_date = Date.parse(trade_date.to_s)
    normalized_snapshot_type = snapshot_type.to_s

    MarketSnapshotCollector.new.collect!(
      trade_date: parsed_trade_date,
      snapshot_type: normalized_snapshot_type
    )
    collect_global_assets(parsed_trade_date, normalized_snapshot_type)
  end

  private

  def collect_global_assets(trade_date, snapshot_type)
    GlobalAssetCollector.new.collect!(
      trade_date: trade_date,
      snapshot_type: snapshot_type
    )
  rescue StandardError => error
    Rails.logger.warn("글로벌자산 후속 수집 실패: #{error.message}")
  end
end
