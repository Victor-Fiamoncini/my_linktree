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
end
