require "rails_helper"

RSpec.describe IconHelper, type: :helper do
  describe "#svg_icon" do
    it "returns the inline SVG for a known icon" do
      expect(helper.svg_icon(:github)).to start_with("<svg").and include("viewBox=")
    end

    it "marks the markup html_safe so ERB renders it instead of escaping it" do
      expect(helper.svg_icon(:linkedin)).to be_html_safe
    end

    it "raises rather than rendering nothing when the icon name is unknown" do
      expect { helper.svg_icon(:mastodon) }.to raise_error(KeyError)
    end

    it "hides every icon from assistive technology, since each one sits beside a text label" do
      described_class::ICONS.each_key do |name|
        expect(helper.svg_icon(name)).to include('aria-hidden="true"')
      end
    end
  end
end
