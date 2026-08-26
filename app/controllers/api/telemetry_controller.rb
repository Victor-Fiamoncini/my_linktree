module Api
  class TelemetryController < BaseController
    def index
      render json: UseCases::ListRecentConnectionsUseCase.new.execute, status: :ok
    rescue => e
      Rails.logger.error(e)
      render json: InternalServerError.new(cause: e), status: :internal_server_error
    end
  end
end
