require "rails_helper"

RSpec.describe LogRedaction do
  describe ".contact" do
    it "keeps the domain and a stable short digest, never the address" do
      result = described_class.contact("jane@example.com")

      expect(result[:contact_domain]).to eq("example.com")
      expect(result[:contact_digest]).to match(/\A[0-9a-f]{12}\z/)
      expect(result[:contact_digest]).to eq(described_class.contact("jane@example.com")[:contact_digest])
      expect(result.values).not_to include("jane@example.com")
    end

    it "distinguishes two people at the same domain" do
      jane = described_class.contact("jane@example.com")
      bob = described_class.contact("bob@example.com")

      expect(jane[:contact_domain]).to eq(bob[:contact_domain])
      expect(jane[:contact_digest]).not_to eq(bob[:contact_digest])
    end

    it "still digests a contact that isn't an email address" do
      result = described_class.contact("+55 11 99999-9999")

      expect(result[:contact_domain]).to be_nil
      expect(result[:contact_digest]).to match(/\A[0-9a-f]{12}\z/)
    end

    it "returns nothing for a blank contact" do
      expect(described_class.contact(nil)).to eq({})
      expect(described_class.contact("")).to eq({})
    end
  end

  describe "the reason these keys aren't named email_*" do
    it "documents that Rails filters event payload keys by substring against config.filter_parameters" do
      subscriber = ActiveSupport::EventReporter::TestHelper::EventSubscriber.new
      Rails.event.subscribe(subscriber)

      begin
        Rails.event.notify("spec.filtering", email_domain: "example.com", contact_domain: "example.com")
      ensure
        Rails.event.unsubscribe(subscriber)
      end

      payload = subscriber.events.last[:payload]
      expect(payload[:email_domain]).to eq("[FILTERED]")
      expect(payload[:contact_domain]).to eq("example.com")
    end
  end
end
