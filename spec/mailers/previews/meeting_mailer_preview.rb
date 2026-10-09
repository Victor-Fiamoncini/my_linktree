# Preview at /rails/mailers/meeting_mailer
class MeetingMailerPreview < ActionMailer::Preview
  def confirmation
    MeetingMailer.confirmation(name: "Jane Doe", email: "jane@example.com", slot_start: "2027-03-03T12:00:00.000Z")
  end

  def notification
    MeetingMailer.notification(name: "Jane Doe", email: "jane@example.com", company: "Acme", slot_start: "2027-03-03T12:00:00.000Z")
  end
end
