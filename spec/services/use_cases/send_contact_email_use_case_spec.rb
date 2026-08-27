require "rails_helper"

RSpec.describe UseCases::SendContactEmailUseCase do
  it "sends a contact email" do
    expect {
      described_class.new.execute(name: "Jane", email: "jane@example.com", message: "Hello!")
    }.to change { ActionMailer::Base.deliveries.size }.by(1)

    mail = ActionMailer::Base.deliveries.last
    expect(mail.subject).to eq("My Linktree - New contact from Jane")
  end

  it "raises ArgumentError when a field is missing" do
    expect {
      described_class.new.execute(name: "", email: "jane@example.com", message: "Hello!")
    }.to raise_error(ArgumentError, "Missing required fields")
  end
end
