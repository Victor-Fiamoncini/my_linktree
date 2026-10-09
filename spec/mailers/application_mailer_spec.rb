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

  it "sends both an HTML and a plain-text part" do
    expect(mail.html_part).to be_present
    expect(mail.text_part).to be_present
  end

  it "wraps the HTML part in the branded layout, with the logo and a link back to the site" do
    html = Nokogiri::HTML(mail.html_part.body.decoded)

    expect(mail.html_part.body.decoded).to start_with("<!DOCTYPE html>")
    expect(html.at_css("img")["src"]).to eq("#{SeoConfig::SITE_URL}/icon.png")
    expect(html.css("a").map { it["href"] }).to include(SeoConfig::SITE_URL, SeoConfig::GITHUB_URL, SeoConfig::LINKEDIN_URL)
    expect(html.at_css("body")["style"]).to include(MailerHelper::FRAPPE[:crust])
  end

  it "signs the text part with a link back to the site" do
    expect(mail.text_part.body.decoded).to include(SeoConfig::SITE_URL)
  end
end
