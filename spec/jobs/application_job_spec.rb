require "rails_helper"

RSpec.describe ApplicationJob, type: :job do
  it "is the Active Job base class for the app's jobs" do
    expect(described_class.superclass).to eq(ActiveJob::Base)
  end
end
