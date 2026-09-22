# frozen_string_literal: true

# Just being in the Gemfile makes the gem's railtie replace Rails' log subscribers and install
# Rack middlewares in every environment. Production wants that — `logrageify!` collapses the
# per-request SQL/render/action noise into one structured http.request event. Dev and test keep
# Rails' own log output, since they never ship anywhere.
#
# The railtie's initializer is declared `after: :load_config_initializers`, so this lands first.
if Rails.env.production?
  Logtail::Config.instance.logrageify!
else
  Logtail::Integrations::Rails.enabled = false
end
