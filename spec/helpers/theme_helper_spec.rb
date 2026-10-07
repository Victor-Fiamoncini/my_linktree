require "rails_helper"

RSpec.describe ThemeHelper, type: :helper do
  describe "#current_theme" do
    it "defaults to Frappé with no cookie" do
      expect(helper.current_theme).to eq("frappe")
    end

    it "honors a known theme from the cookie" do
      helper.request.cookies[:theme] = "latte"

      expect(helper.current_theme).to eq("latte")
    end

    it "falls back to Frappé on an unknown cookie value, since it's rendered into an attribute" do
      helper.request.cookies[:theme] = '"><script>alert(1)</script>'

      expect(helper.current_theme).to eq("frappe")
    end
  end

  describe "#theme_color" do
    it "is Frappé's blue by default" do
      expect(helper.theme_color).to eq("#8caaee")
    end

    it "is Latte's blue under the Latte theme" do
      helper.request.cookies[:theme] = "latte"

      expect(helper.theme_color).to eq("#1e66f5")
    end
  end
end
