require "rails_helper"

RSpec.describe MailerHelper, type: :helper do
  describe "#mail_field" do
    it "renders the label and value as two rows" do
      html = Nokogiri::HTML.fragment(helper.mail_fields { helper.mail_field("Name", "Jane") })

      expect(html.css("tr").map(&:text)).to eq([ "Name", "Jane" ])
    end

    it "keeps the value's line breaks" do
      html = Nokogiri::HTML.fragment(helper.mail_field("Message", "one\ntwo\n\nthree"))

      expect(html.css("br").size).to eq(1)
      expect(html.css("div").map(&:text)).to eq([ "one\ntwo", "three" ])
    end

    it "escapes markup in the value instead of letting simple_format sanitize it" do
      html = Nokogiri::HTML.fragment(helper.mail_field("Message", %(<a href="https://evil.example">x</a>)))

      expect(html.css("a")).to be_empty
      expect(html.text).to include(%(<a href="https://evil.example">x</a>))
    end
  end

  describe "#mail_button" do
    it "links to the url inside a background-colored cell" do
      html = Nokogiri::HTML.fragment(helper.mail_button("Reply", "mailto:jane@example.com"))

      expect(html.at_css("a")["href"]).to eq("mailto:jane@example.com")
      expect(html.at_css("td")["style"]).to include(MailerHelper::FRAPPE[:mauve])
    end
  end

  describe "#mail_heading" do
    it "renders an escaped h1" do
      expect(helper.mail_heading("<b>Hi</b>")).to include("<h1", "&lt;b&gt;Hi&lt;/b&gt;")
    end
  end
end
