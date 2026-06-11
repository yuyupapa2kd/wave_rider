class LeaderSelection < ApplicationRecord
  belongs_to :market_snapshot
  belongs_to :sector
  belongs_to :stock

  validates :market_snapshot_id, uniqueness: { scope: :sector_id }
  validates :stock_id, uniqueness: { scope: :market_snapshot_id }

  def self.select!(market_snapshot:, sector:, stock:)
    transaction do
      where(market_snapshot: market_snapshot, sector: sector).delete_all
      where(market_snapshot: market_snapshot, stock: stock).delete_all
      create!(market_snapshot: market_snapshot, sector: sector, stock: stock)
    end
  end

  def self.unselect!(market_snapshot:, sector:, stock:)
    where(market_snapshot: market_snapshot, sector: sector, stock: stock).delete_all
  end

  def self.clear_for_stock_from!(stock, effective_on)
    joins(:market_snapshot)
      .where(stock: stock)
      .where("market_snapshots.trade_date >= ?", effective_on)
      .delete_all
  end
end
