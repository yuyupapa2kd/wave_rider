class DashboardBuilder
  Group = Struct.new(:sector, :items, :leader_stock_id, keyword_init: true) do
    def total_trade_value
      items.sum(&:trade_value)
    end

    def weighted_change_rate
      return BigDecimal("0") if total_trade_value.zero?

      items.sum { |item| item.trade_value * item.change_rate } / total_trade_value
    end

    def unassigned?
      sector.unassigned?
    end
  end

  def initialize(snapshot)
    @snapshot = snapshot
  end

  def groups
    return [] if @snapshot.blank?

    leaders = @snapshot.leader_selections.index_by(&:sector_id)
    grouped = items.group_by { |item| item.stock.sector_on(@snapshot.trade_date) }

    grouped.map do |sector, sector_items|
      leader_stock_id = leaders[sector.id]&.stock_id
      Group.new(
        sector: sector,
        leader_stock_id: leader_stock_id,
        items: sort_items(sector_items, leader_stock_id)
      )
    end.sort_by { |group| [ group.unassigned? ? 1 : 0, -group.total_trade_value ] }
  end

  private

  def items
    @snapshot.snapshot_items.includes(:daily_metrics, stock: { sector_assignments: :sector }).order(trade_value: :desc)
  end

  def sort_items(items, leader_stock_id)
    items.sort_by { |item| [ item.stock_id == leader_stock_id ? 0 : 1, -item.trade_value ] }
  end
end
