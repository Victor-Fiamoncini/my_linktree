# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data, "https://fonts.gstatic.com"
    policy.img_src     :self, :data
    policy.object_src  :none
    policy.script_src  :self
    policy.style_src   :self, "https://fonts.googleapis.com"
    policy.connect_src :self
    policy.base_uri    :none
    policy.form_action :self
    policy.frame_ancestors :none
  end

  # Only script-src needs a nonce: javascript_importmap_tags renders an inline
  # <script type="importmap"> tag that "self" alone can't authorize. A fresh random nonce per
  # request (rather than the session id) avoids it going blank on requests that never write to
  # the session, which would otherwise produce a predictable empty nonce.
  config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end
