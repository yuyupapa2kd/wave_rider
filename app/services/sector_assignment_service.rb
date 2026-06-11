class SectorAssignmentService
  def initialize(stock:, sector_id:, new_sector_name:, effective_on: Date.current)
    @stock = stock
    @sector_id = sector_id
    @new_sector_name = new_sector_name.to_s.strip
    @effective_on = effective_on
  end

  def call
    sector = resolve_sector
    @stock.assign_sector!(sector: sector, effective_on: @effective_on)
    sector
  end

  private

  def resolve_sector
    return Sector.find_or_create_by!(name: @new_sector_name) if @new_sector_name.present?
    return Sector.find(@sector_id) if @sector_id.present?

    Sector.unassigned
  end
end
