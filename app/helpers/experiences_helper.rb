module ExperiencesHelper
  # accent_class: the category label in an experience; pip_class: the category's square in the stack grid
  TECH_CATEGORIES = [
    { key: :backend, label_key: "experiences_helper.tech_categories.backend", accent_class: "bg-ctp-blue text-on-strong", pip_class: "bg-ctp-blue" },
    { key: :frontend, label_key: "experiences_helper.tech_categories.frontend", accent_class: "bg-ctp-mauve text-on-strong", pip_class: "bg-ctp-mauve" },
    { key: :infra, label_key: "experiences_helper.tech_categories.infra", accent_class: "bg-ctp-green text-on-accent", pip_class: "bg-ctp-green" },
    { key: :other_tools, label_key: "experiences_helper.tech_categories.tools", accent_class: "bg-ctp-yellow text-on-accent", pip_class: "bg-ctp-yellow" }
  ].freeze

  # fill: the panel's header strip; accent: sets --tab-accent, which colors the map node of the selected
  # company and the panel's stepped shadow
  TAB_ACCENTS = [
    { fill: "bg-ctp-blue text-on-strong", accent: "[--tab-accent:var(--color-ctp-blue)]" },
    { fill: "bg-ctp-mauve text-on-strong", accent: "[--tab-accent:var(--color-ctp-mauve)]" },
    { fill: "bg-ctp-green text-on-accent", accent: "[--tab-accent:var(--color-ctp-green)]" },
    { fill: "bg-ctp-yellow text-on-accent", accent: "[--tab-accent:var(--color-ctp-yellow)]" }
  ].freeze

  # The stack grid under the hero. Each item's category and companies come from profile.yml, so the grid
  # can say where something was used without a second, hand-kept list.
  STACK = [
    "Ruby on Rails", "Hotwire", "Node.js", "Golang", "Next.js", "React", "React Native", "TypeScript", "Laravel", "PHP",
    "Postgres", "pgvector", "Redis", "MongoDB", "OpenAI", "RAG", "MCP", "Stripe", "Pusher", "Auth0", "Twilio", "AWS",
    "Docker", "Kamal", "Nginx", "Cloudflare", "GitHub Actions", "Jenkins", "Sentry", "Datadog"
  ].freeze

  def stack_inventory(experiences)
    STACK.map do |tech|
      used_in = experiences.select { |experience| TECH_CATEGORIES.any? { |category| Array(experience[category[:key]]).include?(tech) } }
      category = TECH_CATEGORIES.find { |cat| used_in.any? { |experience| Array(experience[cat[:key]]).include?(tech) } }

      { name: tech, category: category, companies: used_in.map { |experience| experience[:company] }.uniq }
    end
  end

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
