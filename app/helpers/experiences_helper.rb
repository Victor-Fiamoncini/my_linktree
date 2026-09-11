module ExperiencesHelper
  TECH_CATEGORIES = [
    { key: :backend, label_key: "experiences_helper.tech_categories.backend", accent_class: "text-ctp-blue" },
    { key: :frontend, label_key: "experiences_helper.tech_categories.frontend", accent_class: "text-ctp-mauve" },
    { key: :infra, label_key: "experiences_helper.tech_categories.infra", accent_class: "text-ctp-green" },
    { key: :other_tools, label_key: "experiences_helper.tech_categories.tools", accent_class: "text-ctp-yellow" }
  ].freeze

  TAB_ACCENT_CLASSES = [
    "text-ctp-blue min-[900px]:border-ctp-blue",
    "text-ctp-mauve min-[900px]:border-ctp-mauve",
    "text-ctp-green min-[900px]:border-ctp-green",
    "text-ctp-yellow min-[900px]:border-ctp-yellow"
  ].freeze

  def format_experience_date(date_str)
    return t("experiences_helper.present") if date_str.blank?

    I18n.l(Date.parse("#{date_str}-01"), format: "%b %Y")
  end

  def experience_duration(start_date, end_date)
    start_year, start_month = start_date.split("-").map(&:to_i)
    end_year, end_month = end_date.present? ? end_date.split("-").map(&:to_i) : [ Date.current.year, Date.current.month ]

    total_months = (end_year - start_year) * 12 + (end_month - start_month)
    years = total_months / 12
    months = total_months % 12

    parts = []
    parts << t("experiences_helper.duration.year", count: years) if years > 0
    parts << t("experiences_helper.duration.month", count: months) if months > 0

    parts.any? ? parts.join(" ") : t("experiences_helper.duration.less_than_a_month")
  end
end
