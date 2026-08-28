class MeetingMailer < ApplicationMailer
  def confirmation(name:, email:, slot_start:)
    @name = name
    @slot_start = slot_start

    mail(to: email, subject: "My Linktree - Meeting scheduled")
  end

  def notification(name:, email:, company:, slot_start:)
    @name = name
    @email = email
    @company = company
    @slot_start = slot_start

    mail(to: Rails.application.credentials.dig(:mailer, :recipient_email), subject: "My Linktree - New meeting booked by #{name}")
  end
end
