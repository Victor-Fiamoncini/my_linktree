module LogRedaction
  module_function

  # Not named `email_*`: Rails 8.1 filters event payloads with a substring-matching
  # ParameterFilter, so `email_domain` would arrive as "[FILTERED]". Pinned by a spec.
  def contact(value)
    return {} if value.blank?

    value = value.to_s

    {
      contact_domain: value.include?("@") ? value.split("@").last : nil,
      contact_digest: Digest::SHA256.hexdigest(value).first(12)
    }
  end
end
