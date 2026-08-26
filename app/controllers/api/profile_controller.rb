module Api
  class ProfileController < BaseController
    def show
      render json: UseCases::GetProfileUseCase.new.execute, status: :ok
    rescue => e
      Rails.logger.error(e)
      render json: InternalServerError.new(cause: e), status: :internal_server_error
    end
  end
end
