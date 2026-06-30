class GlobalAssetSnapshot < ApplicationRecord
  validates :trade_date, :snapshot_type, :category, :asset_code, :name, :source, :source_symbol, :captured_at, presence: true
  validates :snapshot_type, inclusion: { in: MarketSnapshot::SNAPSHOT_TYPES.keys }
  validates :price, :change_value, :change_rate, numericality: true
  validates :category_position, :position, numericality: { only_integer: true }
  validates :asset_code, uniqueness: { scope: [ :trade_date, :snapshot_type ] }

  scope :for_snapshot, ->(trade_date, snapshot_type) { where(trade_date: trade_date, snapshot_type: snapshot_type) }
  scope :display_order, -> { order(:category_position, :position) }
end
