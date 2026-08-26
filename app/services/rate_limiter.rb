class RateLimiter
  def initialize(key_prefix:, max_requests:, window:, store: Rails.cache)
    @key_prefix = key_prefix
    @max_requests = max_requests
    @window = window
    @store = store
  end

  # Skips rate limiting entirely when identifier is blank, matching the previous
  # behavior of skipping when neither x-forwarded-for nor x-real-ip is present.
  def allowed?(identifier)
    return true if identifier.blank?

    count = @store.increment("rate_limiter:#{@key_prefix}:#{identifier}", 1, expires_in: @window)
    count.present? && count <= @max_requests
  end
end
