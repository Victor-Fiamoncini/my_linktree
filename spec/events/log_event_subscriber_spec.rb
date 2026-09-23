require "rails_helper"

RSpec.describe LogEventSubscriber do
  let(:logger) { instance_double(ActiveSupport::Logger) }

  before { allow(Rails).to receive(:logger).and_return(logger) }

  it "writes the event name followed by its payload as JSON" do
    expect(logger).to receive(:info).with('[contact.message.sent] {"locale":"en"}')

    described_class.new.emit(name: "contact.message.sent", payload: { locale: "en" }, tags: nil)
  end

  it "appends tags when the event carries any" do
    expect(logger).to receive(:info).with('[mcp.request] {"tool":"get_resume"} tags=["mcp"]')

    described_class.new.emit(name: "mcp.request", payload: { tool: "get_resume" }, tags: [ "mcp" ])
  end

  it "logs an empty object for an event with no payload" do
    expect(logger).to receive(:info).with("[api.error] {}")

    described_class.new.emit(name: "api.error", payload: nil, tags: nil)
  end

  it "omits the tags segment when tags are present but empty" do
    expect(logger).to receive(:info).with("[api.error] {}")

    described_class.new.emit(name: "api.error", payload: {}, tags: [])
  end

  it "satisfies the subscriber interface Rails.event calls" do
    expect(described_class.new).to respond_to(:emit)
  end
end
