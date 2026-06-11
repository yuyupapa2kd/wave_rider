class SnapshotItem < ApplicationRecord
  belongs_to :market_snapshot
  belongs_to :stock
  has_many :daily_metrics, -> { order(metric_date: :desc) }, dependent: :destroy

  validates :trade_value, :volume, :current_price, numericality: { only_integer: true }
  validates :change_rate, numericality: true

  def chart_url
    "https://ssl.pstatic.net/imgfinance/chart/item/candle/day/#{stock.ticker}.png"
  end
end
