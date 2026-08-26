class ContactMailer < ApplicationMailer
  def new_contact(name:, email:, message:)
    @name = name
    @email = email
    @message = message

    mail(to: ENV.fetch("MAILER_RECIPIENT_EMAIL"), subject: "My Linktree - New contact from #{name}")
  end
end
