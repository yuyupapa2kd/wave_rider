class CollectMarketSnapshotJob < ApplicationJob
  queue_as :default

  discard_on StandardError

  def perform(snapshot_type, trade_date = Date.current.to_s)
    MarketSnapshotCollector.new.collect!(
      trade_date: Date.parse(trade_date.to_s),
      snapshot_type: snapshot_type.to_s
    )
  end
end
