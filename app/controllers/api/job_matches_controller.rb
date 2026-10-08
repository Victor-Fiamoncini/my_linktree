module Api
  class JobMatchesController < FormController
    rate_limit to: 3, within: 10.minutes, by: -> { rate_limit_identifier }, only: :create
    rate_limit to: 10, within: 1.day, name: "daily", by: -> { rate_limit_identifier }, only: :create
    rate_limit to: MatchJobUseCase::GLOBAL_DAILY_LIMIT, within: 1.day, name: "global", scope: :job_match, by: -> { "all" }, with: :render_budget_exhausted, if: -> { MatchJobUseCase.acceptable?(params[:job_description]) }, only: :create

    rescue_from ArgumentError, with: :render_declined
    rescue_from ValidationError, with: :render_validation_error

    def create
      result = JobMatchEvents.completed(surface: "web") do
        MatchJobUseCase.new.execute(job_description: params[:job_description])
      end

      render json: { summary: result[:summary].sum("") { |paragraph| paragraph[:text] } }, status: :ok
    end

    private

    def render_validation_error(e)
      Rails.event.notify("job_match.rejected", severity: "warn", surface: "web", reason: e.errors.keys.join(","))

      render json: { message: localized(:validation_failed), errors: e.errors }, status: :unprocessable_content
    end

    def render_declined(e)
      Rails.event.notify("job_match.rejected", severity: "warn", surface: "web", reason: e.message)

      render json: { message: localized(:declined) }, status: :unprocessable_content
    end

    def render_budget_exhausted
      Rails.event.notify("job_match.budget_exhausted", severity: "error", surface: "web")

      render json: { message: localized(:budget_exhausted) }, status: :too_many_requests
    end

    def event_namespace
      "job_match"
    end
  end
end
