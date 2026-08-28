module UseCases
  class ListServicesUseCase
    def initialize(config: Rails.application.config_for(:profile))
      @config = config
    end

    def execute
      @config[:services]
    end
  end
end
