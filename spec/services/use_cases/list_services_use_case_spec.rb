require "rails_helper"

RSpec.describe UseCases::ListServicesUseCase do
  let(:config) do
    {
      services: [
        {
          id: 1,
          translations: {
            en: { name: "Consulting", description: "We consult." },
            "pt-BR": { name: "Consultoria", description: "Nós consultamos." }
          }
        }
      ]
    }
  end

  it "returns the services localized to the given locale" do
    result = described_class.new(config: config).execute(locale: :en)

    expect(result).to eq([ { id: 1, name: "Consulting", description: "We consult." } ])
  end

  it "returns the services localized to pt-BR" do
    result = described_class.new(config: config).execute(locale: :"pt-BR")

    expect(result).to eq([ { id: 1, name: "Consultoria", description: "Nós consultamos." } ])
  end

  it "defaults to the current I18n locale when none is given" do
    I18n.with_locale(:"pt-BR") do
      result = described_class.new(config: config).execute

      expect(result.first[:name]).to eq("Consultoria")
    end
  end
end
