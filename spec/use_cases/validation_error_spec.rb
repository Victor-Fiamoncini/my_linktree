require "rails_helper"

RSpec.describe ValidationError do
  it "is an ArgumentError, so the generic rescue paths still catch it" do
    expect(described_class.new({})).to be_a(ArgumentError)
  end

  it "exposes the per-field errors the contact and hire forms highlight" do
    error = described_class.new(name: "can't be blank", email: "is invalid")

    expect(error.errors).to eq(name: "can't be blank", email: "is invalid")
  end

  it "joins the field messages into the exception message" do
    error = described_class.new(name: "can't be blank", email: "is invalid")

    expect(error.message).to eq("can't be blank, is invalid")
  end

  it "is raised by both use cases that back a form" do
    expect { SendContactEmailUseCase.new.execute(name: "", email: "", message: "") }
      .to raise_error(described_class)
    expect { SendHireRequestUseCase.new.execute(name: "", contact: "", brief: "") }
      .to raise_error(described_class)
  end
end
