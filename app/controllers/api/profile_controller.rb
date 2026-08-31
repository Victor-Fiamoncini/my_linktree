module Api
  class ProfileController < BaseController
    rate_limit to: 60, within: 1.minute, by: -> { rate_limit_identifier }, only: :show

    def show
      render json: UseCases::GetProfileUseCase.new.execute, status: :ok
    end
  end
end
