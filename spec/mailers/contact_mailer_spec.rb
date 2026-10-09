require "rails_helper"

RSpec.describe ContactMailer do
  def fields(mail) = Nokogiri::HTML(mail.html_part.body.decoded).css("td").map { it.text.squish }.each_cons(2).to_h
  def text_body(mail) = mail.text_part.body.decoded

  let(:recipient) { Rails.application.credentials.dig(:mailer, :recipient_email) }

  describe "#new_contact" do
    let(:mail) { described_class.new_contact(name: "Jane", email: "jane@example.com", message: "Hello there") }

    it "addresses the inbox configured in the credentials" do
      expect(mail.to).to eq([ recipient ])
    end

    it "names the sender in the subject so the inbox is scannable" do
      expect(mail.subject).to eq("My Linktree - New contact from Jane")
    end

    it "includes the name, address and message in both parts" do
      expect(fields(mail)).to include("Name" => "Jane", "Email" => "jane@example.com", "Message" => "Hello there")
      expect(text_body(mail)).to include("Name: Jane", "Email: jane@example.com", "Hello there")
    end

    it "offers a reply button addressed to the sender" do
      expect(Nokogiri::HTML(mail.html_part.body.decoded).css("a[href='mailto:jane@example.com']")).to be_present
    end
  end

  describe "#agent_hire_request" do
    let(:mail) do
      described_class.agent_hire_request(name: "Jane", contact: "jane@example.com", brief: "Build an API", agent: "Claude")
    end

    it "addresses the inbox configured in the credentials" do
      expect(mail.to).to eq([ recipient ])
    end

    it "distinguishes itself from a human contact in the subject" do
      expect(mail.subject).to eq("My Linktree - Agent contact from Jane")
    end

    it "includes the brief and the calling agent in both parts" do
      expect(fields(mail)).to include("Name" => "Jane", "Contact" => "jane@example.com", "Brief" => "Build an API", "Agent" => "Claude")
      expect(text_body(mail)).to include("Name: Jane", "Contact: jane@example.com", "Build an API", "Agent: Claude")
    end

    it "omits the agent line entirely when the caller didn't identify itself" do
      mail = described_class.agent_hire_request(name: "Jane", contact: "jane@example.com", brief: "Build an API")

      expect(fields(mail)).to include("Brief" => "Build an API")
      expect(fields(mail)).not_to have_key("Agent")
      expect(text_body(mail)).not_to include("Agent:")
    end
  end
end
