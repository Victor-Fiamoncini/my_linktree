module UseCases
  class ListServicesUseCase
    def initialize(config: Rails.application.config_for(:profile))
      @config = config
    end

    def execute(locale: I18n.locale)
      @config[:services].map do |service|
        translation = service[:translations][locale.to_sym] || service[:translations][:en]
        service.except(:translations).merge(translation)
      end
    end
  end
end
