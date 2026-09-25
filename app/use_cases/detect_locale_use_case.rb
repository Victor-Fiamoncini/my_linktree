class DetectLocaleUseCase
  # Cloudflare's "couldn't place this client" sentinels — no country.
  UNKNOWN_COUNTRY_CODES = %w[XX T1].freeze
  LANGUAGE_LOCALES = { "pt" => :"pt-BR", "en" => :en }.freeze

  def execute(country_code: nil, accept_language: nil)
    country = country_code.to_s.scrub.strip.upcase

    return from_country(country) unless country.empty? || UNKNOWN_COUNTRY_CODES.include?(country)

    from_accept_language(accept_language)
  end

  private

  def from_country(country)
    country == "BR" ? :"pt-BR" : I18n.default_locale
  end

  def from_accept_language(accept_language)
    accept_language.to_s.scrub.downcase.split(",")
      .filter_map { |range| LANGUAGE_LOCALES[range[/[a-z]+/]] }
      .first || I18n.default_locale
  end
end
