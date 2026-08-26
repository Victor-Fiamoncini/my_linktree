class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAILER_SENDER_EMAIL") }
  layout "mailer"
end
