class DailyMetric < ApplicationRecord
  belongs_to :snapshot_item

  validates :metric_date, presence: true
  validates :metric_date, uniqueness: { scope: :snapshot_item_id }
end
