class ApplicationMailer < ActionMailer::Base
  default from: -> { Rails.application.credentials.dig(:mailer, :sender_email) }
  layout "mailer"
end
