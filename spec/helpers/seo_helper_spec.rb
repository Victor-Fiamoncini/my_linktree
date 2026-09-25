require "rails_helper"

RSpec.describe SeoHelper, type: :helper do
  describe "#default_title" do
    it "combines the author and the localized job title" do
      expect(helper.default_title).to eq("Victor Fiamoncini - Software Engineer")

      I18n.with_locale(:"pt-BR") do
        expect(helper.default_title).to eq("Victor Fiamoncini - Engenheiro de Software")
      end
    end
  end

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

  describe "#canonical_path" do
    it "falls back to the request path" do
      allow(helper.request).to receive(:path).and_return("/en")

      expect(helper.canonical_path).to eq("/en")
    end

    it "prefers the path provided by the view" do
      helper.content_for(:canonical, "/pt-BR/telemetry")

      expect(helper.canonical_path).to eq("/pt-BR/telemetry")
    end
  end
end
