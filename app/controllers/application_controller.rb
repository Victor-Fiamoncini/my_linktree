class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :switch_locale
  before_action :set_event_context
  before_action :set_default_description

  def default_url_options
    { locale: I18n.locale }
  end

  private

  # Reads params[:locale] generically, so it works both from the "/:locale" route
  # segment on page requests and from a "locale" field in a JSON POST body (e.g.
  # the contact form) — no per-controller override needed either way.
  def switch_locale(&action)
    locale = params[:locale].presence_in(I18n.available_locales.map(&:to_s)) || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def set_default_description
    xp_years = GetXpYearsUseCase.new.execute

    @default_description = t("seo.default_description", xp_years: xp_years)
  end

  # Attached to every Rails.event.notify call made while serving the request, so individual events
  # don't repeat it. Rails clears it per request in the executor's `to_complete` hook.
  def set_event_context
    Rails.event.set_context(
      request_id: request.request_id,
      ip: rate_limit_identifier,
      path: request.path,
      user_agent: request.user_agent
    )
  end

  # Prefers Cloudflare's CF-Connecting-IP over Rails' X-Forwarded-For-based request.remote_ip.
  # Confirmed empirically (both from this sandbox and from a real browser session) that
  # X-Forwarded-For arrives corrupted — some hop between Cloudflare and the origin replaces the
  # real visitor IP with a Cloudflare-owned one, most visibly for IPv6 clients hitting this
  # IPv4-only origin. CF-Connecting-IP is Cloudflare's own dedicated header for this exact
  # purpose and isn't subject to that corruption. It's safe to trust unconditionally here because
  # the origin firewall (see README's Cloudflare section) only accepts connections from
  # Cloudflare's IP ranges — nobody can reach this app to forge the header without going through
  # Cloudflare's edge, which always sets it to the true connecting IP itself. Falls back to
  # request.remote_ip for local dev/test, where there's no Cloudflare in front at all.
  def rate_limit_identifier
    request.headers["CF-Connecting-IP"].presence || request.remote_ip
  end
end
