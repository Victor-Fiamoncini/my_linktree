class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_default_description

  private

  def set_default_description
    xp_years = UseCases::GetXpYearsUseCase.new.execute

    @default_description =
      "Software Engineer with #{xp_years} years of experience in both companies and freelance projects. " \
      "Currently focused on back-end development using PHP (Laravel/Symfony) and NodeJS, while also " \
      "building personal projects with Ruby on Rails and Next.js."
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
