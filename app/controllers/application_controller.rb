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
    I18n.with_locale(request_locale, &action)
  end

  def request_locale
    params[:locale].presence_in(I18n.available_locales.map(&:to_s)) || I18n.default_locale
  rescue ActionDispatch::Http::Parameters::ParseError
    I18n.default_locale
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
      ip: request.remote_ip,
      path: request.path,
      user_agent: request.user_agent
    )
  end
end
