require "rails_helper"

# The base mailer has no action of its own, so its two settings are asserted through a concrete
# mail — which is also the only way they can break in production.
RSpec.describe ApplicationMailer do
  let(:mail) { ContactMailer.new_contact(name: "Jane", email: "jane@example.com", message: "Hi") }

  it "sends from the address in the credentials rather than a hardcoded one" do
    expect(mail.from).to eq([ Rails.application.credentials.dig(:mailer, :sender_email) ])
  end

  it "resolves the sender per delivery, so a credential change needs no redeploy of the class" do
    allow(Rails.application.credentials).to receive(:dig).with(:mailer, :sender_email).and_return("other@example.com")
    allow(Rails.application.credentials).to receive(:dig).with(:mailer, :recipient_email).and_call_original

    expect(ContactMailer.new_contact(name: "Jane", email: "jane@example.com", message: "Hi").from)
      .to eq([ "other@example.com" ])
  end

  it "wraps every mail in the shared mailer layout" do
    expect(mail.body.encoded).to include("<!DOCTYPE html>", "<html>")
  end
end
