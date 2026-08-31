module Api
  class TelemetryController < BaseController
    rate_limit to: 60, within: 1.minute, by: -> { rate_limit_identifier }, only: :index

    def index
      render json: UseCases::ListRecentConnectionsUseCase.new.execute, status: :ok
    end
  end
end
