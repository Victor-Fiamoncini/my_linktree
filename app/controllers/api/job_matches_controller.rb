module Api
  class JobMatchesController < FormController
    rate_limit to: 3, within: 10.minutes, by: -> { rate_limit_identifier }, only: :create
    rate_limit to: 10, within: 1.day, name: "daily", by: -> { rate_limit_identifier }, only: :create
    rate_limit to: MatchJobUseCase::GLOBAL_DAILY_LIMIT, within: 1.day, name: "global", scope: :job_match, by: -> { "all" }, with: -> { render_error :too_many_requests, "job_match.budget_exhausted", { message: localized(:budget_exhausted) }, severity: "error", surface: "web" }, if: -> { MatchJobUseCase.acceptable?(params[:job_description]) }, only: :create

    rescue_from ArgumentError do |e|
      render_error :unprocessable_content, "job_match.rejected", { message: localized(:declined) }, surface: "web", reason: e.message
    end

    rescue_from ValidationError do |e|
      render_error :unprocessable_content, "job_match.rejected", { message: localized(:validation_failed), errors: e.errors },
        surface: "web", reason: e.errors.keys.join(",")
    end

    def create
      result = JobMatchEvents.completed(surface: "web") do
        MatchJobUseCase.new.execute(job_description: params[:job_description])
      end

      render json: { summary: result[:summary].sum("") { |paragraph| paragraph[:text] } }, status: :ok
    end

    private

    def event_namespace
      "job_match"
    end
  end
end
