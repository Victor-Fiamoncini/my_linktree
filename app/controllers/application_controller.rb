class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  around_action :switch_locale
  before_action :set_event_context

  def default_url_options
    { locale: I18n.locale }
  end

  private

  def switch_locale(&action)
    locale = params[:locale].presence_in(I18n.available_locales.map(&:to_s)) || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def detected_locale
    DetectLocaleUseCase.new.execute(
      country_code: request.headers["CF-IPCountry"],
      accept_language: request.headers["Accept-Language"]
    )
  end

  def set_event_context
    Rails.event.set_context(
      request_id: request.request_id,
      ip: rate_limit_identifier,
      path: request.path,
      user_agent: request.user_agent
    )
  end

  def rate_limit_identifier
    request.headers["CF-Connecting-IP"].presence || request.remote_ip
  end
end
