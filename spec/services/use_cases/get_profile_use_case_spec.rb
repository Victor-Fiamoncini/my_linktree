require "rails_helper"

RSpec.describe UseCases::GetProfileUseCase do
  it "returns the profile from the config" do
    config = { name: "Jane", experiences: [], education: [] }

    result = described_class.new(config: config).execute

    expect(result).to eq(name: "Jane", experiences: [], education: [])
  end
end
