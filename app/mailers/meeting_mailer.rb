class MeetingMailer < ApplicationMailer
  def confirmation(name:, email:, slot_start:)
    @name = name
    @slot_start = humanize_slot(slot_start)

    mail(to: email, subject: "My Linktree - Meeting scheduled")
  end

  def notification(name:, email:, company:, slot_start:)
    @name = name
    @email = email
    @company = company
    @slot_start = humanize_slot(slot_start)

    mail(to: Rails.application.credentials.dig(:mailer, :recipient_email), subject: "My Linktree - New meeting booked by #{name}")
  end

  private

  def humanize_slot(slot_start)
    zone = ActiveSupport::TimeZone[Rails.application.config_for(:availability)[:timezone]]
    time = zone.parse(slot_start)

    "#{time.strftime('%A, %B %-d, %Y at %-I:%M %p')} (#{zone.name})"
  end
end
