module Api
  class HireController < BaseController
    rate_limit to: 2, within: 10.minutes, by: -> { rate_limit_identifier }, only: :create

    rescue_from UseCases::SendHireRequestUseCase::ValidationError, with: :render_validation_error

    def create
      UseCases::RecordAgentConnectionUseCase.new.execute(tool: "hire")

      UseCases::SendHireRequestUseCase.new.execute(**hire_params)

      render json: { message: "Thanks! I'll get back to you soon." }, status: :ok
    end

    private

    def hire_params
      params.permit(:name, :contact, :brief, :agent).to_h.symbolize_keys
    end

    def render_validation_error(e)
      render json: { message: "Check the highlighted fields and try again.", errors: e.errors }, status: :unprocessable_content
    end
  end
end
