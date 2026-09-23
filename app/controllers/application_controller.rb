class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  around_action :switch_locale
  before_action :set_event_context
  before_action :set_default_description

  def default_url_options
    { locale: I18n.locale }
  end

  private

  # Generic params[:locale] read: serves both the "/:locale" route segment and a "locale" field
  # in a JSON POST body.
  def switch_locale(&action)
    locale = params[:locale].presence_in(I18n.available_locales.map(&:to_s)) || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def set_default_description
    xp_years = GetXpYearsUseCase.new.execute

    @default_description = t("seo.default_description", xp_years: xp_years)
  end

  # Attached to every Rails.event.notify in the request; Rails clears it per request.
  def set_event_context
    Rails.event.set_context(
      request_id: request.request_id,
      ip: rate_limit_identifier,
      path: request.path,
      user_agent: request.user_agent
    )
  end

  # X-Forwarded-For arrives corrupted behind Cloudflare (collapses every visitor into one
  # bucket); CF-Connecting-IP is safe to trust unconditionally here — see CLAUDE.md.
  def rate_limit_identifier
    request.headers["CF-Connecting-IP"].presence || request.remote_ip
  end
end
