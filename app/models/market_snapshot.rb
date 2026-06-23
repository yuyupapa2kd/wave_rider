class MarketSnapshot < ApplicationRecord
  SNAPSHOT_TYPES = {
    "intraday" => "14:30 장중",
    "closing" => "16:00 장마감 확정"
  }.freeze

  STATUSES = %w[pending collecting success failed skipped].freeze

  has_many :snapshot_items, dependent: :destroy
  has_many :stocks, through: :snapshot_items
  has_many :leader_selections, dependent: :destroy
  has_many :collection_logs, dependent: :destroy

  validates :trade_date, presence: true
  validates :snapshot_type, inclusion: { in: SNAPSHOT_TYPES.keys }
  validates :status, inclusion: { in: STATUSES }
  validates :trade_date, uniqueness: { scope: :snapshot_type }

  scope :latest_first, -> { order(trade_date: :desc, snapshot_type: :asc) }

  def snapshot_type_label
    SNAPSHOT_TYPES.fetch(snapshot_type)
  end

  def display_name
    "#{trade_date} / #{snapshot_type_label}"
  end

  def successful_data?
    snapshot_items.exists?
  end

  def simple_failure_message
    failure_message.presence || "수집 실패"
  end
end
