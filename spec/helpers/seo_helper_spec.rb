require "rails_helper"

RSpec.describe SeoHelper, type: :helper do
  describe "#default_description" do
    it "interpolates the years of experience in the current locale" do
      travel_to Time.zone.local(2026, 6, 1) do
        expect(helper.default_description).to start_with("Software Engineer with 7 years of experience")

        I18n.with_locale(:"pt-BR") do
          expect(helper.default_description).to start_with("Engenheiro de Software com 7 anos de experiência")
        end
      end
    end
  end
end
