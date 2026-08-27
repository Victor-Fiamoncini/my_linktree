require "rails_helper"

RSpec.describe UseCases::ListServicesUseCase do
  it "returns the services from the config" do
    config = { services: [ { name: "Consulting" } ] }

    result = described_class.new(config: config).execute

    expect(result).to eq([ { name: "Consulting" } ])
  end
end
