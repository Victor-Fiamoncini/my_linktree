require "rails_helper"

RSpec.describe UseCases::ListServicesUseCase do
  it "returns the services from the database" do
    database = double("database", services: [ { name: "Consulting" } ])

    result = described_class.new(database: database).execute

    expect(result).to eq([ { name: "Consulting" } ])
  end
end
