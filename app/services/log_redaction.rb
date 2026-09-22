module LogRedaction
  module_function

  # Keeps enough to tell a prospect from a bot and to recognise the same person across two events,
  # without the address itself reaching a third-party log store.
  #
  # Not named `email_*` on purpose: Rails 8.1 runs every event payload through an
  # ActiveSupport::ParameterFilter built from `config.filter_parameters`, which matches keys by
  # substring — and `:email` is filtered, so `email_domain` would arrive as "[FILTERED]".
  def contact(value)
    return {} if value.blank?

    value = value.to_s

    {
      contact_domain: value.include?("@") ? value.split("@").last : nil,
      contact_digest: Digest::SHA256.hexdigest(value).first(12)
    }
  end
end
