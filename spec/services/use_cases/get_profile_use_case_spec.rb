require "rails_helper"

RSpec.describe UseCases::GetProfileUseCase do
  it "returns the profile from the database" do
    database = double("database", profile: { name: "Jane" })

    result = described_class.new(database: database).execute

    expect(result).to eq(name: "Jane")
  end
end
