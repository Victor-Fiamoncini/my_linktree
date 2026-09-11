module UseCases
  class GetProfileUseCase
    def initialize(config: Rails.application.config_for(:profile))
      @config = config
    end

    def execute(locale: I18n.locale)
      {
        name: @config[:name],
        experiences: localize_entries(@config[:experiences], locale),
        education: localize_entries(@config[:education], locale)
      }
    end

    private

    def localize_entries(entries, locale)
      entries.map do |entry|
        translation = entry[:translations][locale.to_sym] || entry[:translations][:en]
        entry.except(:translations).merge(translation)
      end
    end
  end
end
