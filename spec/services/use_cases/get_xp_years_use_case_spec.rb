require "rails_helper"

RSpec.describe UseCases::GetXpYearsUseCase do
  it "returns the number of years since the start year of work" do
    travel_to Time.utc(2027, 3, 1) do
      expect(described_class.new.execute).to eq(8)
    end
  end

  it "exposes the start year of work" do
    expect(described_class.new.start_year_of_work).to eq(2019)
  end
end
