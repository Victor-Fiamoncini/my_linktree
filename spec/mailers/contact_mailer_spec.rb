require "rails_helper"

RSpec.describe ContactMailer do
  let(:recipient) { Rails.application.credentials.dig(:mailer, :recipient_email) }

  describe "#new_contact" do
    let(:mail) { described_class.new_contact(name: "Jane", email: "jane@example.com", message: "Hello there") }

    it "addresses the inbox configured in the credentials" do
      expect(mail.to).to eq([ recipient ])
    end

    it "names the sender in the subject so the inbox is scannable" do
      expect(mail.subject).to eq("My Linktree - New contact from Jane")
    end

    it "includes the name, address and message in the body" do
      expect(mail.body.encoded).to include("Name: Jane", "Email: jane@example.com", "Message: Hello there")
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

    it "includes the brief and the calling agent in the body" do
      expect(mail.body.encoded).to include("Name: Jane", "Contact: jane@example.com", "Brief: Build an API", "Agent: Claude")
    end

    it "omits the agent line entirely when the caller didn't identify itself" do
      mail = described_class.agent_hire_request(name: "Jane", contact: "jane@example.com", brief: "Build an API")

      expect(mail.body.encoded).to include("Brief: Build an API")
      expect(mail.body.encoded).not_to include("Agent:")
    end
  end
end
