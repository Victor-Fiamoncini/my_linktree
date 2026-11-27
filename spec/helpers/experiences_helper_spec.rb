require "rails_helper"

RSpec.describe ExperiencesHelper, type: :helper do
  describe "#format_experience_date" do
    it "returns the translated 'Present' label for a blank end date" do
      expect(helper.format_experience_date(nil)).to eq("Present")

      I18n.with_locale(:"pt-BR") { expect(helper.format_experience_date(nil)).to eq("Atual") }
    end

    it "formats a year-month string as an abbreviated month and year" do
      expect(helper.format_experience_date("2024-03")).to eq("Mar 2024")
    end
  end

  describe "#experience_duration" do
    it "pluralizes years and months in English" do
      expect(helper.experience_duration("2023-01", "2024-05")).to eq("1 year 4 months")
    end

    it "pluralizes years and months in pt-BR" do
      I18n.with_locale(:"pt-BR") do
        expect(helper.experience_duration("2023-01", "2024-05")).to eq("1 ano 4 meses")
      end
    end

    it "returns the translated 'less than a month' label for very short spans" do
      expect(helper.experience_duration("2024-01", "2024-01")).to eq("Less than a month")

      I18n.with_locale(:"pt-BR") do
        expect(helper.experience_duration("2024-01", "2024-01")).to eq("Menos de um mês")
      end
    end
  end

  describe "#stack_inventory" do
    let(:experiences) do
      [
        { company: "Acme", backend: [ "Ruby on Rails", "Postgres" ], frontend: [ "React" ], infra: [], other_tools: [] },
        { company: "Initech", backend: [ "Postgres" ], frontend: [], infra: [ "Docker" ], other_tools: [] },
        { company: "Acme", backend: [ "Postgres" ], frontend: [], infra: [], other_tools: [] }
      ]
    end

    it "lists every stack item, in order" do
      expect(helper.stack_inventory(experiences).map { |item| item[:name] }).to eq(described_class::STACK)
    end

    it "names each company that used an item once, in profile order" do
      postgres = helper.stack_inventory(experiences).find { |item| item[:name] == "Postgres" }

      expect(postgres[:companies]).to eq(%w[Acme Initech])
    end

    it "takes the category from the first list the item appears in" do
      items = helper.stack_inventory(experiences).index_by { |item| item[:name] }

      expect(items["Ruby on Rails"][:category][:key]).to eq(:backend)
      expect(items["React"][:category][:key]).to eq(:frontend)
      expect(items["Docker"][:category][:key]).to eq(:infra)
    end

    it "leaves an item no experience lists without a category or companies" do
      golang = helper.stack_inventory(experiences).find { |item| item[:name] == "Golang" }

      expect(golang).to include(category: nil, companies: [])
    end
  end
end
