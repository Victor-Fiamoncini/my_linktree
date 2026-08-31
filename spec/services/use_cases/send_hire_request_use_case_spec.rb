require "rails_helper"

RSpec.describe UseCases::SendHireRequestUseCase do
  let(:valid_params) { { name: "Jane", contact: "jane@example.com", brief: "Build me a thing" } }

  it "sends a hire request email" do
    expect {
      perform_enqueued_jobs do
        described_class.new.execute(**valid_params)
      end
    }.to change { ActionMailer::Base.deliveries.size }.by(1)

    mail = ActionMailer::Base.deliveries.last
    expect(mail.subject).to eq("My Linktree - Agent contact from Jane")
  end

  it "succeeds without the optional agent field" do
    expect {
      perform_enqueued_jobs do
        described_class.new.execute(**valid_params)
      end
    }.not_to raise_error
  end

  it "enqueues a background job to deliver the email with the given params" do
    described_class.new.execute(**valid_params, agent: "claude")

    assert_enqueued_email_with ContactMailer, :agent_hire_request,
      args: [ { name: "Jane", contact: "jane@example.com", brief: "Build me a thing", agent: "claude" } ]
  end

  it "enqueues the background job with a nil agent when the field is omitted" do
    described_class.new.execute(**valid_params)

    assert_enqueued_email_with ContactMailer, :agent_hire_request,
      args: [ { name: "Jane", contact: "jane@example.com", brief: "Build me a thing", agent: nil } ]
  end

  it "raises a ValidationError (a kind of ArgumentError) with a name error when name is blank" do
    expect {
      described_class.new.execute(**valid_params.merge(name: ""))
    }.to raise_error(described_class::ValidationError) { |error|
      expect(error).to be_a(ArgumentError)
      expect(error.errors).to eq(name: "can't be blank")
    }
  end

  it "raises with a contact error when contact is blank" do
    expect {
      described_class.new.execute(**valid_params.merge(contact: ""))
    }.to raise_error(described_class::ValidationError) { |error|
      expect(error.errors).to eq(contact: "can't be blank")
    }
  end

  it "raises with a brief error when brief is blank" do
    expect {
      described_class.new.execute(**valid_params.merge(brief: ""))
    }.to raise_error(described_class::ValidationError) { |error|
      expect(error.errors).to eq(brief: "can't be blank")
    }
  end

  it "raises with multiple errors when several fields are blank" do
    expect {
      described_class.new.execute(name: "", contact: "", brief: "")
    }.to raise_error(described_class::ValidationError) { |error|
      expect(error.errors.keys).to contain_exactly(:name, :contact, :brief)
    }
  end
end
