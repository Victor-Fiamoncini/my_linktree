require "rails_helper"

RSpec.describe MeetingMailer do
  let(:slot_start) { "2027-03-03T12:00:00.000Z" }

  describe "#confirmation" do
    let(:mail) { described_class.confirmation(name: "Jane", email: "jane@example.com", slot_start: slot_start) }

    it "humanizes the slot into the availability timezone instead of the raw ISO string" do
      expect(mail.body.encoded).to include("Wednesday, March 3, 2027 at 9:00 AM (America/Sao_Paulo)")
      expect(mail.body.encoded).not_to include(slot_start)
    end
  end

  describe "#notification" do
    it "includes the company line when a company was informed" do
      mail = described_class.notification(name: "Jane", email: "jane@example.com", company: "Acme", slot_start: slot_start)

      expect(mail.body.encoded).to include("Company: Acme")
    end

    it "omits the company line entirely when no company was informed" do
      mail = described_class.notification(name: "Jane", email: "jane@example.com", company: nil, slot_start: slot_start)

      expect(mail.body.encoded).not_to include("Company:")
    end

    it "humanizes the slot into the availability timezone instead of the raw ISO string" do
      mail = described_class.notification(name: "Jane", email: "jane@example.com", company: "Acme", slot_start: slot_start)

      expect(mail.body.encoded).to include("Wednesday, March 3, 2027 at 9:00 AM (America/Sao_Paulo)")
      expect(mail.body.encoded).not_to include(slot_start)
    end
  end
end
