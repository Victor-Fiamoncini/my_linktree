module Api
  class TelemetryController < BaseController
    def index
      render json: UseCases::ListRecentConnectionsUseCase.new.execute, status: :ok
    end
  end
end
