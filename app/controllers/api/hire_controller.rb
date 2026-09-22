module Api
  class HireController < BaseController
    rate_limit to: 2, within: 10.minutes, by: -> { rate_limit_identifier }, only: :create

    rescue_from UseCases::SendHireRequestUseCase::ValidationError, with: :render_validation_error

    def create
      UseCases::RecordAgentConnectionUseCase.new.execute(tool: "hire")

      UseCases::SendHireRequestUseCase.new.execute(**hire_params)

      Rails.event.notify(
        "hire.request.received",
        agent: hire_params[:agent],
        brief_length: hire_params[:brief].to_s.length,
        **LogRedaction.contact(hire_params[:contact])
      )

      render json: { message: "Thanks! I'll get back to you soon." }, status: :ok
    end

    private

    def hire_params
      params.permit(:name, :contact, :brief, :agent).to_h.symbolize_keys
    end

    def render_validation_error(e)
      Rails.event.notify("hire.request.rejected", severity: "warn", fields: e.errors.keys.map(&:to_s))

      render json: { message: "Check the highlighted fields and try again.", errors: e.errors }, status: :unprocessable_content
    end
  end
end
