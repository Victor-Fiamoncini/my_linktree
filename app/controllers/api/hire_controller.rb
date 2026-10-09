module Api
  class HireController < PublicController
    rate_limit to: 2, within: 10.minutes, by: -> { rate_limit_identifier }, only: :create

    rescue_from ValidationError do |e|
      render_error :unprocessable_content, "hire.request.rejected", { message: "Check the highlighted fields and try again.", errors: e.errors },
        fields: e.errors.keys.map(&:to_s)
    end

    def create
      RecordAgentConnectionUseCase.new.execute(tool: "hire")

      SendHireRequestUseCase.new.execute(**hire_params)

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
  end
end
