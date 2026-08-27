module Api
  class ProfileController < BaseController
    def show
      render json: UseCases::GetProfileUseCase.new.execute, status: :ok
    end
  end
end
