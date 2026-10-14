# Production sits behind Cloudflare → kamal-proxy (forward_headers: true, see config/deploy.yml)
# → Thruster, so X-Forwarded-For arrives as "<visitor>, <cloudflare edge>, <kamal-proxy>". Rails'
# default trusted_proxies (loopback/private) skip the kamal-proxy hop but stop at Cloudflare's
# edge, so request.remote_ip — the default key of every rate_limit, and the event context's ip —
# would be a Cloudflare IP, collapsing per-IP rate limiting into a handful of shared buckets.
#
# A request whose last hop isn't Cloudflare resolves to that hop, so forged X-Forwarded-For
# entries are ignored even without the origin firewall (see README's Cloudflare section), which
# stays as defense in depth. CF-Connecting-IP isn't used for the same reason.
#
# Ranges from https://www.cloudflare.com/ips/ (Cloudflare rotates these infrequently). Keep them
# in sync with the Hetzner Cloud Firewall's 80/443 rules.
CLOUDFLARE_IP_RANGES = %w[
  173.245.48.0/20 103.21.244.0/22 103.22.200.0/22 103.31.4.0/22 141.101.64.0/18
  108.162.192.0/18 190.93.240.0/20 188.114.96.0/20 197.234.240.0/22 198.41.128.0/17
  162.158.0.0/15 104.16.0.0/13 104.24.0.0/14 172.64.0.0/13 131.0.72.0/22
  2400:cb00::/32 2606:4700::/32 2803:f800::/32 2405:b500::/32 2405:8100::/32
  2a06:98c0::/29 2c0f:f248::/32
].freeze

Rails.application.config.action_dispatch.trusted_proxies =
  ActionDispatch::RemoteIp::TRUSTED_PROXIES + CLOUDFLARE_IP_RANGES.map { |range| IPAddr.new(range) }
