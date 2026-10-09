require "rails_helper"

RSpec.describe MeetingMailer do
  def html_text(mail) = Nokogiri::HTML(mail.html_part.body.decoded).text.squish
  def fields(mail) = Nokogiri::HTML(mail.html_part.body.decoded).css("td").map { it.text.squish }.each_cons(2).to_h

  let(:slot_start) { "2027-03-03T12:00:00.000Z" }

  describe "#confirmation" do
    let(:mail) { described_class.confirmation(name: "Jane", email: "jane@example.com", slot_start: slot_start) }

    it "greets the visitor by name" do
      expect(html_text(mail)).to include("Hi Jane,")
      expect(mail.text_part.body.decoded).to include("Hi Jane,")
    end

    it "humanizes the slot into the availability timezone instead of the raw ISO string" do
      expect(html_text(mail)).to include("Wednesday, March 3, 2027 at 9:00 AM (America/Sao_Paulo)")
      expect(mail.body.encoded).not_to include(slot_start)
    end
  end

  describe "#notification" do
    it "includes the company line when a company was informed" do
      mail = described_class.notification(name: "Jane", email: "jane@example.com", company: "Acme", slot_start: slot_start)

      expect(fields(mail)).to include("Company" => "Acme")
      expect(mail.text_part.body.decoded).to include("Company: Acme")
    end

    it "omits the company line entirely when no company was informed" do
      mail = described_class.notification(name: "Jane", email: "jane@example.com", company: nil, slot_start: slot_start)

      expect(fields(mail)).not_to have_key("Company")
      expect(mail.text_part.body.decoded).not_to include("Company:")
    end

    it "humanizes the slot into the availability timezone instead of the raw ISO string" do
      mail = described_class.notification(name: "Jane", email: "jane@example.com", company: "Acme", slot_start: slot_start)

      expect(html_text(mail)).to include("Wednesday, March 3, 2027 at 9:00 AM (America/Sao_Paulo)")
      expect(mail.body.encoded).not_to include(slot_start)
    end
  end
end
