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

  describe "#mail_px_box" do
    def box(**options)
      Nokogiri::HTML.fragment(helper.mail_px_box(fill: "#111111", line: "#222222", **options) { "hi" })
    end

    it "outlines the content with notched corners" do
      rows = box.css("tr")

      expect(rows.size).to eq(3)
      expect(rows[1].css("td")[1].text).to eq("hi")
      expect(rows[1].css("td")[1]["style"]).to include("#111111")
      [ rows.first, rows.last ].each do |row|
        expect(row.css("td").map { it["style"].include?("#222222") }).to eq([ false, true, false ])
      end
    end

    it "adds a stepped drop shadow on the right and bottom" do
      rows = box(drop: "#333333", unit: 2).css("tr")

      expect(rows.size).to eq(4)
      expect(rows[1].css("td").last["style"]).to include("#333333", "width:2px")
      expect(rows.last.css("td").map { it["style"].include?("#333333") }).to eq([ false, true, true, false ])
    end
  end

  describe "#mail_button" do
    it "links to the url inside a background-colored cell" do
      html = Nokogiri::HTML.fragment(helper.mail_button("Reply", "mailto:jane@example.com"))

      expect(html.at_css("a")["href"]).to eq("mailto:jane@example.com")
      expect(html.at_css("a").parent["style"]).to include(MailerHelper::FRAPPE[:blue])
    end
  end

  describe "#mail_prompt" do
    it "renders an escaped chip on the given accent" do
      html = Nokogiri::HTML.fragment(helper.mail_prompt("$ <b>meet</b>", :green))

      expect(html.at_css("p").text).to eq("$ <b>meet</b>")
      expect(html.at_css("p").parent["style"]).to include(MailerHelper::FRAPPE[:green])
    end
  end

  describe "#mail_heading" do
    it "renders an escaped h1" do
      expect(helper.mail_heading("<b>Hi</b>")).to include("<h1", "&lt;b&gt;Hi&lt;/b&gt;")
    end
  end
end
