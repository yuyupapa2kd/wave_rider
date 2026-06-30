module ApplicationHelper
  SECTOR_PREVIEW_UP_COLORS = %w[#fee2e2 #fecaca #fca5a5 #f87171 #ef4444 #dc2626].freeze
  SECTOR_PREVIEW_DOWN_COLORS = %w[#dbeafe #bfdbfe #93c5fd #60a5fa #3b82f6 #2563eb].freeze
  SECTOR_PREVIEW_NEUTRAL_COLOR = "#7b8790"
  SECTOR_PREVIEW_CHANGE_UP_COLOR = "#dc2626"
  SECTOR_PREVIEW_CHANGE_DOWN_COLOR = "#2563eb"

  def format_ekrw(value)
    number = value.to_i / 100_000_000.0
    return "#{number_with_delimiter(number.round)}억" if number >= 10

    "#{number.round(1)}억"
  end

  def format_percent(value)
    "#{number_with_precision(value, precision: 2)}%"
  end

  def format_signed_number(value)
    number = value.to_i
    sign = number.positive? ? "+" : ""
    "#{sign}#{number_with_delimiter(number)}"
  end

  def format_compact_signed_number(value)
    number = value.to_i
    sign = number.positive? ? "+" : ""
    abs_number = number.abs

    formatted =
      if abs_number >= 100_000_000
        "#{number_with_precision(abs_number / 100_000_000.0, precision: 1, strip_insignificant_zeros: true)}억"
      elsif abs_number >= 10_000
        "#{number_with_precision(abs_number / 10_000.0, precision: 1, strip_insignificant_zeros: true)}만"
      else
        number_with_delimiter(abs_number)
      end

    "#{sign}#{formatted}"
  end

  def status_label(snapshot)
    return "미수집" if snapshot.blank?

    {
      "pending" => "대기",
      "collecting" => "수집중",
      "success" => "성공",
      "failed" => "실패",
      "skipped" => "비거래일"
    }.fetch(snapshot.status, snapshot.status)
  end

  def sector_preview_groups(groups)
    groups.to_a.reject(&:unassigned?).sort_by { |group| -group.total_trade_value }
  end

  def sector_preview_color(change_rate)
    rate = BigDecimal(change_rate.to_s)
    return SECTOR_PREVIEW_NEUTRAL_COLOR if rate.zero?

    colors = rate.positive? ? SECTOR_PREVIEW_UP_COLORS : SECTOR_PREVIEW_DOWN_COLORS
    color_index = [ (rate.abs / 5).floor + 1, colors.size ].min - 1
    colors[color_index]
  end

  def sector_preview_change_color(change_rate)
    rate = BigDecimal(change_rate.to_s)
    return SECTOR_PREVIEW_NEUTRAL_COLOR if rate.zero?

    rate.positive? ? SECTOR_PREVIEW_CHANGE_UP_COLOR : SECTOR_PREVIEW_CHANGE_DOWN_COLOR
  end

  def sector_preview_pie_slices(groups)
    chart_groups = sector_preview_chart_groups(groups)
    total_trade_value = chart_groups.sum { |group| group.fetch(:trade_value) }
    return [] if total_trade_value.zero?

    offset = 0.0
    total = total_trade_value.to_f

    chart_groups.map do |group|
      share = group.fetch(:trade_value).to_f / total
      start_angle = offset * 360 - 90
      offset += share
      end_angle = offset * 360 - 90
      mid_angle = (start_angle + end_angle) / 2

      {
        name: group.fetch(:name),
        color: sector_preview_color(group.fetch(:change_rate)),
        full_circle: share >= 0.9999,
        path: sector_preview_slice_path(start_angle, end_angle),
        label: group.fetch(:name),
        label_x: sector_preview_polar_point(50, 50, 28, mid_angle).first,
        label_y: sector_preview_polar_point(50, 50, 28, mid_angle).last
      }
    end
  end

  def sector_preview_chart_groups(groups)
    top_groups = groups.first(3).map do |group|
      {
        name: group.sector.name,
        trade_value: group.total_trade_value,
        change_rate: group.weighted_change_rate
      }
    end
    other_groups = groups.drop(3)
    return top_groups if other_groups.empty?

    other_trade_value = other_groups.sum(&:total_trade_value)
    other_change_rate =
      if other_trade_value.zero?
        BigDecimal("0")
      else
        other_groups.sum { |group| group.total_trade_value * group.weighted_change_rate } / other_trade_value
      end

    top_groups + [
      {
        name: "기타",
        trade_value: other_trade_value,
        change_rate: other_change_rate
      }
    ]
  end

  def sector_preview_slice_path(start_angle, end_angle)
    center_x = 50
    center_y = 50
    radius = 46
    start_x, start_y = sector_preview_polar_point(center_x, center_y, radius, start_angle)
    end_x, end_y = sector_preview_polar_point(center_x, center_y, radius, end_angle)
    large_arc = end_angle - start_angle > 180 ? 1 : 0

    [
      "M #{format_svg_number(center_x)} #{format_svg_number(center_y)}",
      "L #{format_svg_number(start_x)} #{format_svg_number(start_y)}",
      "A #{format_svg_number(radius)} #{format_svg_number(radius)} 0 #{large_arc} 1 #{format_svg_number(end_x)} #{format_svg_number(end_y)}",
      "Z"
    ].join(" ")
  end

  def sector_preview_polar_point(center_x, center_y, radius, angle)
    radians = angle * Math::PI / 180
    [
      center_x + radius * Math.cos(radians),
      center_y + radius * Math.sin(radians)
    ]
  end

  def format_svg_number(number)
    number_with_precision(number, precision: 4, strip_insignificant_zeros: true)
  end
end
