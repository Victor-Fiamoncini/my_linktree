require "rails_helper"

RSpec.describe UseCases::GetProfileUseCase do
  let(:config) do
    {
      name: "Jane",
      experiences: [
        {
          id: 1,
          company: "Acme",
          translations: {
            en: { role: "Engineer", description: "Built things." },
            "pt-BR": { role: "Engenheira", description: "Construiu coisas." }
          }
        }
      ],
      education: [
        {
          id: 1,
          institution: "Acme University",
          translations: {
            en: { degree: "Bachelor", field: "CS" },
            "pt-BR": { degree: "Bacharelado", field: "CC" }
          }
        }
      ]
    }
  end

  it "returns the profile localized to the given locale" do
    result = described_class.new(config: config).execute(locale: :en)

    expect(result).to eq(
      name: "Jane",
      experiences: [ { id: 1, company: "Acme", role: "Engineer", description: "Built things." } ],
      education: [ { id: 1, institution: "Acme University", degree: "Bachelor", field: "CS" } ]
    )
  end

  it "returns the profile localized to pt-BR" do
    result = described_class.new(config: config).execute(locale: :"pt-BR")

    expect(result[:experiences].first).to include(role: "Engenheira", description: "Construiu coisas.")
    expect(result[:education].first).to include(degree: "Bacharelado", field: "CC")
  end

  it "falls back to English when the requested locale has no translation" do
    result = described_class.new(config: config).execute(locale: :fr)

    expect(result[:experiences].first).to include(role: "Engineer")
  end

  it "defaults to the current I18n locale when none is given" do
    I18n.with_locale(:"pt-BR") do
      result = described_class.new(config: config).execute

      expect(result[:experiences].first).to include(role: "Engenheira")
    end
  end
end
