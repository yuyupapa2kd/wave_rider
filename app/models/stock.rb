class Stock < ApplicationRecord
  has_many :sector_assignments, dependent: :destroy
  has_many :snapshot_items, dependent: :destroy
  has_many :leader_selections, dependent: :destroy

  validates :ticker, presence: true, uniqueness: true
  validates :name, presence: true

  def sector_on(date)
    assignment = sector_assignments.includes(:sector)
                                   .where("effective_on <= ?", date)
                                   .order(effective_on: :desc, id: :desc)
                                   .first
    assignment&.sector || Sector.unassigned
  end

  def assign_sector!(sector:, effective_on:)
    transaction do
      sector_assignments.find_or_initialize_by(effective_on: effective_on).tap do |assignment|
        assignment.sector = sector
        assignment.save!
      end

      LeaderSelection.clear_for_stock_from!(self, effective_on)
    end
  end
end
