module ExperiencesHelper
  TECH_CATEGORIES = [
    { key: :backend, label_key: "experiences_helper.tech_categories.backend", accent_class: "bg-ctp-blue text-on-strong" },
    { key: :frontend, label_key: "experiences_helper.tech_categories.frontend", accent_class: "bg-ctp-mauve text-on-strong" },
    { key: :infra, label_key: "experiences_helper.tech_categories.infra", accent_class: "bg-ctp-green text-on-accent" },
    { key: :other_tools, label_key: "experiences_helper.tech_categories.tools", accent_class: "bg-ctp-yellow text-on-accent" }
  ].freeze

  # fill: the active tab and the panel's header strip; shadow: the panel's hard shadow
  TAB_ACCENTS = [
    { fill: "bg-ctp-blue text-on-strong", shadow: "shadow-ctp-blue" },
    { fill: "bg-ctp-mauve text-on-strong", shadow: "shadow-ctp-mauve" },
    { fill: "bg-ctp-green text-on-accent", shadow: "shadow-ctp-green" },
    { fill: "bg-ctp-yellow text-on-accent", shadow: "shadow-ctp-yellow" }
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
