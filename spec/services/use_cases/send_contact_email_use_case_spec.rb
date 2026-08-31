require "rails_helper"

RSpec.describe UseCases::SendContactEmailUseCase do
  it "sends a contact email" do
    expect {
      perform_enqueued_jobs do
        described_class.new.execute(name: "Jane", email: "jane@example.com", message: "Hello!")
      end
    }.to change { ActionMailer::Base.deliveries.size }.by(1)

    mail = ActionMailer::Base.deliveries.last
    expect(mail.subject).to eq("My Linktree - New contact from Jane")
  end

  it "enqueues a background job to deliver the email with the given params" do
    described_class.new.execute(name: "Jane", email: "jane@example.com", message: "Hello!")

    assert_enqueued_email_with ContactMailer, :new_contact,
      args: [ { name: "Jane", email: "jane@example.com", message: "Hello!" } ]
  end

  it "raises a ValidationError (a kind of ArgumentError) with a name error when name is blank" do
    expect {
      described_class.new.execute(name: "", email: "jane@example.com", message: "Hello!")
    }.to raise_error(described_class::ValidationError) { |error|
      expect(error).to be_a(ArgumentError)
      expect(error.errors).to eq(name: "can't be blank")
    }
  end

  it "raises with an email error when email is blank" do
    expect {
      described_class.new.execute(name: "Jane", email: "", message: "Hello!")
    }.to raise_error(described_class::ValidationError) { |error|
      expect(error.errors).to eq(email: "can't be blank")
    }
  end

  it "raises with an email error when email is malformed" do
    expect {
      described_class.new.execute(name: "Jane", email: "not-an-email", message: "Hello!")
    }.to raise_error(described_class::ValidationError) { |error|
      expect(error.errors).to eq(email: "is invalid")
    }
  end

  it "raises with a message error when message is blank" do
    expect {
      described_class.new.execute(name: "Jane", email: "jane@example.com", message: "")
    }.to raise_error(described_class::ValidationError) { |error|
      expect(error.errors).to eq(message: "can't be blank")
    }
  end

  it "raises with multiple errors when several fields are blank" do
    expect {
      described_class.new.execute(name: "", email: "", message: "")
    }.to raise_error(described_class::ValidationError) { |error|
      expect(error.errors.keys).to contain_exactly(:name, :email, :message)
    }
  end
end
