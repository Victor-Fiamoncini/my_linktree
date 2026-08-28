class ContactMailer < ApplicationMailer
  def new_contact(name:, email:, message:)
    @name = name
    @email = email
    @message = message

    mail(to: Rails.application.credentials.dig(:mailer, :recipient_email), subject: "My Linktree - New contact from #{name}")
  end
end
