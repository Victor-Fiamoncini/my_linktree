class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_default_description
  after_action :add_temporary_ip_debug_headers, if: -> { params[:_debug_ip].present? }

  private

  def set_default_description
    xp_years = UseCases::GetXpYearsUseCase.new.execute

    @default_description =
      "Software Engineer with #{xp_years} years of experience in both companies and freelance projects. " \
      "Currently focused on back-end development using PHP (Laravel/Symfony) and NodeJS, while also " \
      "building personal projects with Ruby on Rails and Next.js."
  end

  # Rails' own trusted-proxy-aware IP resolution — honors X-Forwarded-For/X-Real-IP only when
  # they come from a trusted proxy (loopback/private ranges, plus Cloudflare's published ranges —
  # see config/initializers/trusted_proxies.rb, since production sits entirely behind Cloudflare),
  # and otherwise falls back to the real connection IP. Unlike reading those headers directly, a
  # client can't spoof this to dodge rate limiting.
  def rate_limit_identifier
    request.remote_ip
  end

  # TEMPORARY — diagnosing why request.remote_ip resolves to Cloudflare's edge IP instead of the
  # real visitor IP in production. Remove once resolved.
  def add_temporary_ip_debug_headers
    response.headers["X-Debug-Xff"] = request.headers["X-Forwarded-For"].inspect
    response.headers["X-Debug-Remote-Addr"] = request.remote_addr.inspect
    response.headers["X-Debug-Remote-Ip"] = request.remote_ip.inspect
    response.headers["X-Debug-Cf-Connecting-Ip"] = request.headers["CF-Connecting-IP"].inspect
    response.headers["X-Debug-True-Client-Ip"] = request.headers["True-Client-IP"].inspect
    response.headers["X-Debug-X-Real-Ip"] = request.headers["X-Real-IP"].inspect
    response.headers["X-Debug-Cf-Ray"] = request.headers["CF-RAY"].inspect
  end
end
