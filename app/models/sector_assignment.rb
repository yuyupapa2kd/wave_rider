class SectorAssignment < ApplicationRecord
  belongs_to :stock
  belongs_to :sector

  validates :effective_on, presence: true
  validates :stock_id, uniqueness: { scope: :effective_on }
end
