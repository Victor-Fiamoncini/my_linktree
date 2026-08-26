module Api
  class ContactsController < BaseController
    RATE_LIMITER = RateLimiter.new(key_prefix: "contact", max_requests: 2, window: 10.minutes)

    def create
      ip = request.headers["X-Forwarded-For"] || request.headers["X-Real-IP"]

      unless RATE_LIMITER.allowed?(ip)
        return render json: TooManyRequestsError.new, status: :too_many_requests
      end

      UseCases::SendContactEmailUseCase.new.execute(**contact_params)

      head :no_content
    rescue MissingRequiredFieldsError => e
      render json: e, status: :bad_request
    rescue => e
      Rails.logger.error(e)
      render json: InternalServerError.new(cause: e), status: :internal_server_error
    end

    private

    def contact_params
      { name: params[:name], email: params[:email], message: params[:message] }
    end
  end
end
