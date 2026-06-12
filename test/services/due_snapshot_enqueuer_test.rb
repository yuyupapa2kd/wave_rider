require "test_helper"

class DueSnapshotEnqueuerTest < ActiveSupport::TestCase
  test "enqueues missing intraday snapshot after intraday due time" do
    now = Time.zone.local(2026, 6, 12, 15, 5)

    assert_difference -> { MarketSnapshot.where(trade_date: now.to_date, snapshot_type: "intraday").count }, 1 do
      assert_difference -> { SolidQueue::Job.where(class_name: "CollectMarketSnapshotJob").count }, 1 do
        DueSnapshotEnqueuer.new(now: now).enqueue_due!
      end
    end

    snapshot = MarketSnapshot.find_by!(trade_date: now.to_date, snapshot_type: "intraday")
    assert_equal "collecting", snapshot.status
  end

  test "does not enqueue duplicate snapshots" do
    now = Time.zone.local(2026, 6, 12, 15, 5)
    MarketSnapshot.create!(trade_date: now.to_date, snapshot_type: "intraday", status: "success")

    assert_no_difference -> { MarketSnapshot.count } do
      assert_no_difference -> { SolidQueue::Job.where(class_name: "CollectMarketSnapshotJob").count } do
        DueSnapshotEnqueuer.new(now: now).enqueue_due!
      end
    end
  end

  test "enqueues both snapshots after closing due time" do
    now = Time.zone.local(2026, 6, 12, 16, 5)

    assert_difference -> { MarketSnapshot.count }, 2 do
      DueSnapshotEnqueuer.new(now: now).enqueue_due!
    end

    assert MarketSnapshot.exists?(trade_date: now.to_date, snapshot_type: "intraday")
    assert MarketSnapshot.exists?(trade_date: now.to_date, snapshot_type: "closing")
  end
end
