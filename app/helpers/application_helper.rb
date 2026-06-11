module ApplicationHelper
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
end
