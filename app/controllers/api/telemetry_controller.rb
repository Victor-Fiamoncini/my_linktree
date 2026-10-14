module Api
  class TelemetryController < PublicController
    rate_limit to: 60, within: 1.minute, only: :index

    def index
      render json: ListRecentConnectionsUseCase.new.execute, status: :ok
    end
  end
end
