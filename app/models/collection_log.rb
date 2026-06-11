class CollectionLog < ApplicationRecord
  belongs_to :market_snapshot, optional: true

  validates :level, :stage, :occurred_at, presence: true
end
