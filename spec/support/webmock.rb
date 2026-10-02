require "webmock/rspec"

# Cuprite drives Chrome over localhost, so only external hosts are blocked.
WebMock.disable_net_connect!(allow_localhost: true)
