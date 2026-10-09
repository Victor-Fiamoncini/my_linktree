require "rails_helper"

# Visitor input lands in HTML mail bodies, in subjects and, for bookings, in the To: header.
RSpec.describe "Email injection", type: :request do
  let(:json_headers) { { "Content-Type" => "application/json", "Accept" => "application/json" } }
  let(:markup) { %(<script>alert(1)</script><a href="https://evil.example">click</a>) }
  let(:crlf) { "Jane\r\nBcc: victim@evil.example\r\n\r\n<h1>forged body</h1>" }

  def deliver(path, params)
    perform_enqueued_jobs { post path, params: params.to_json, headers: json_headers }
  end

  def book_slot(arguments)
    headers = json_headers.merge("Accept" => "application/json, text/event-stream")
    rpc = ->(name, args) { { jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: name, arguments: args } }.to_json }

    post "/api/mcp", params: rpc.call("check_availability", {}), headers: headers
    slot = JSON.parse(response.parsed_body.dig("result", "content", 0, "text"))["slots"].first

    perform_enqueued_jobs { post "/api/mcp", params: rpc.call("schedule_meeting", arguments.merge(slot_start: slot)), headers: headers }
    response.parsed_body.dig("result", "content", 0, "text")
  end

  def html_body(mail)
    Nokogiri::HTML((mail.html_part || mail).body.decoded)
  end

  shared_examples "inert markup" do
    it "escapes it in every mail body" do
      expect(ActionMailer::Base.deliveries).not_to be_empty

      ActionMailer::Base.deliveries.each do |mail|
        expect(html_body(mail).css("script, a[href='https://evil.example']")).to be_empty
        expect(html_body(mail).text).to include(markup)
      end
    end
  end

  context "through the contact form" do
    before { deliver("/api/contact", name: "Jane", email: "jane@example.com", message: markup) }

    it_behaves_like "inert markup"
  end

  context "through the hire API" do
    before { deliver("/api/hire", name: "Jane", contact: "jane@example.com", brief: markup, agent: markup) }

    it_behaves_like "inert markup"
  end

  context "through a booking" do
    before { book_slot(name: markup, email: "jane@example.com", company: markup) }

    it_behaves_like "inert markup"
  end

  it "can't add headers or a body through a name in the subject" do
    deliver("/api/contact", name: crlf, email: "jane@example.com", message: "Hi")
    deliver("/api/hire", name: crlf, contact: "jane@example.com", brief: "Hi")

    expect(ActionMailer::Base.deliveries.size).to eq(2)

    ActionMailer::Base.deliveries.each do |mail|
      expect(mail.bcc).to be_nil
      expect(mail.to).to eq([ Rails.application.credentials.dig(:mailer, :recipient_email) ])
      expect(html_body(mail).css("h1").map(&:text)).not_to include("forged body")
      expect(html_body(mail).text).to include("<h1>forged body</h1>")
    end
  end

  it "rejects a booking whose email smuggles in another recipient" do
    expect {
      text = book_slot(name: "Jane", email: "jane@example.com\r\nBcc: victim@evil.example")
      expect(text).to eq("Slot unavailable")
    }.not_to change(Booking, :count)

    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "rejects a contact email that smuggles in another recipient" do
    deliver("/api/contact", name: "Jane", email: "jane@example.com\nBcc: victim@evil.example", message: "Hi")

    expect(response).to have_http_status(:unprocessable_content)
    expect(ActionMailer::Base.deliveries).to be_empty
  end
end
