module ExperiencesHelper
  MONTH_NAMES = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec].freeze

  TECH_CATEGORIES = [
    { key: :backend, label: "Backend", accent_class: "text-ctp-blue" },
    { key: :frontend, label: "Frontend", accent_class: "text-ctp-mauve" },
    { key: :infra, label: "Infra", accent_class: "text-ctp-green" },
    { key: :other_tools, label: "Tools", accent_class: "text-ctp-yellow" }
  ].freeze

  TAB_ACCENT_CLASSES = [
    "text-ctp-blue min-[900px]:border-ctp-blue",
    "text-ctp-mauve min-[900px]:border-ctp-mauve",
    "text-ctp-green min-[900px]:border-ctp-green",
    "text-ctp-yellow min-[900px]:border-ctp-yellow"
  ].freeze

  def format_experience_date(date_str)
    return "Present" if date_str.blank?

    year, month = date_str.split("-")
    "#{MONTH_NAMES[month.to_i - 1]} #{year}"
  end

  def experience_duration(start_date, end_date)
    start_year, start_month = start_date.split("-").map(&:to_i)
    end_year, end_month = end_date.present? ? end_date.split("-").map(&:to_i) : [ Date.current.year, Date.current.month ]

    total_months = (end_year - start_year) * 12 + (end_month - start_month)
    years = total_months / 12
    months = total_months % 12

    parts = []
    parts << "#{years} year#{"s" if years > 1}" if years > 0
    parts << "#{months} month#{"s" if months > 1}" if months > 0

    parts.any? ? parts.join(" ") : "Less than a month"
  end
end
