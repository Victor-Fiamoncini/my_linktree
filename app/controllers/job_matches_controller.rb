class JobMatchesController < ApplicationController
  GLOBAL_DAILY_LIMIT = 100

  rate_limit to: 3, within: 10.minutes, by: -> { rate_limit_identifier }, only: :create
  rate_limit to: 10, within: 1.day, name: "daily", by: -> { rate_limit_identifier }, only: :create
  rate_limit to: GLOBAL_DAILY_LIMIT, within: 1.day, name: "global", scope: :job_match, by: -> { "all" }, with: :render_budget_exhausted, if: -> { MatchJobUseCase.acceptable?(params[:job_description]) }, only: :create

  rescue_from StandardError, with: :render_internal_error
  rescue_from ActionDispatch::Http::Parameters::ParseError, with: :render_bad_request
  rescue_from ArgumentError, with: :render_declined
  rescue_from ValidationError, with: :render_validation_error
  rescue_from ActionController::TooManyRequests, with: :render_too_many_requests
  rescue_from ActionController::InvalidAuthenticityToken, with: :render_invalid_authenticity_token

  def create
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = MatchJobUseCase.new.execute(job_description: params[:job_description])

    Rails.event.notify(
      "job_match.completed",
      surface: "web",
      sources: result[:sources].size,
      duration_ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round,
      **usage_payload(result[:usage])
    )

    # The page shows plain prose; citations are only returned to MCP clients.
    render json: { summary: result[:summary].sum("") { |paragraph| paragraph[:text] } }, status: :ok
  end

  private

  def usage_payload(usage)
    { llm_input: usage[:input_tokens], llm_output: usage[:output_tokens] }
  end

  def render_validation_error(e)
    Rails.event.notify("job_match.rejected", severity: "warn", surface: "web", reason: e.errors.keys.join(","))

    render json: { message: t("job_matches.validation_failed", locale: request_locale), errors: e.errors }, status: :unprocessable_content
  end

  def render_declined(e)
    Rails.event.notify("job_match.rejected", severity: "warn", surface: "web", reason: e.message)

    render json: { message: t("job_matches.declined", locale: request_locale) }, status: :unprocessable_content
  end

  def render_too_many_requests
    Rails.event.notify("job_match.rate_limited", severity: "warn")

    render json: { message: t("job_matches.too_many_requests", locale: request_locale) }, status: :too_many_requests
  end

  def render_budget_exhausted
    Rails.event.notify("job_match.budget_exhausted", severity: "error", surface: "web")

    render json: { message: t("job_matches.budget_exhausted", locale: request_locale) }, status: :too_many_requests
  end

  def render_invalid_authenticity_token
    Rails.event.notify("job_match.csrf_rejected", severity: "warn")

    render json: { message: t("job_matches.invalid_authenticity_token", locale: request_locale) }, status: :unprocessable_content
  end

  # See Api::BaseController#render_internal_server_error.
  def render_internal_error(e)
    Rails.logger.error("#{e.class}: #{e.message}")

    Rails.event.notify(
      "job_match.error",
      severity: "error",
      error_class: e.class.name,
      error_message: e.message,
      backtrace: e.backtrace&.first(5)
    )

    render json: { message: t("job_matches.internal_error", locale: request_locale) }, status: :internal_server_error
  end
end
