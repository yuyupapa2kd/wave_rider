class Sector < ApplicationRecord
  UNASSIGNED_NAME = "미지정"

  has_many :sector_assignments, dependent: :restrict_with_exception
  has_many :leader_selections, dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :named, -> { where.not(name: UNASSIGNED_NAME).order(:name) }

  def self.unassigned
    find_or_create_by!(name: UNASSIGNED_NAME)
  end

  def unassigned?
    name == UNASSIGNED_NAME
  end
end
