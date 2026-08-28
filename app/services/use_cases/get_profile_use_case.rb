module UseCases
  class GetProfileUseCase
    def initialize(config: Rails.application.config_for(:profile))
      @config = config
    end

    def execute
      { name: @config[:name], experiences: @config[:experiences], education: @config[:education] }
    end
  end
end
