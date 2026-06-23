class DueSnapshotEnqueuer
  SCHEDULES = {
    "intraday" => { hour: 14, min: 30 },
    "closing" => { hour: 16, min: 0 }
  }.freeze

  def initialize(now: Time.zone.now)
    @now = now
  end

  def enqueue_due!
    SCHEDULES.each_key.filter_map do |snapshot_type|
      enqueue_snapshot(snapshot_type) if due?(snapshot_type)
    end
  end

  private

  attr_reader :now

  def due?(snapshot_type)
    schedule = SCHEDULES.fetch(snapshot_type)
    now >= now.change(hour: schedule.fetch(:hour), min: schedule.fetch(:min), sec: 0)
  end

  def enqueue_snapshot(snapshot_type)
    trade_date = now.to_date
    return if MarketSnapshot.exists?(trade_date: trade_date, snapshot_type: snapshot_type)

    snapshot = MarketSnapshot.create!(
      trade_date: trade_date,
      snapshot_type: snapshot_type,
      status: "collecting",
      started_at: now
    )
    CollectMarketSnapshotJob.perform_later(snapshot_type, trade_date.to_s)
    snapshot
  end
end
