require "rails_helper"

# These constants are rendered into canonical tags, JSON-LD, the sitemap and the MCP server
# description, where a malformed value fails silently rather than raising.
RSpec.describe SeoConfig do
  it "derives the MCP endpoint and icon URLs from the site URL, so one edit moves them all" do
    expect(described_class::MCP_ENDPOINT).to eq("#{described_class::SITE_URL}/api/mcp")
    expect(described_class::MCP_ICON_192).to start_with(described_class::SITE_URL)
    expect(described_class::MCP_ICON_512).to start_with(described_class::SITE_URL)
  end

  it "serves every URL over absolute https" do
    urls = [
      described_class::SITE_URL, described_class::LINKEDIN_URL, described_class::GITHUB_URL,
      described_class::CATPPUCCIN_URL, described_class::MCP_ENDPOINT,
      described_class::MCP_ICON_192, described_class::MCP_ICON_512
    ]

    expect(urls).to all(start_with("https://"))
  end

  it "keeps the site URL free of a trailing slash, since everything concatenates onto it" do
    expect(described_class::SITE_URL).not_to end_with("/")
  end

  it "points the MCP icons at files that actually ship in public/" do
    [ described_class::MCP_ICON_192, described_class::MCP_ICON_512 ].each do |url|
      expect(Rails.public_path.join(url.delete_prefix("#{described_class::SITE_URL}/"))).to exist
    end
  end

  it "keeps SITE_LAST_MODIFIED a real date, which the sitemap's <lastmod> requires" do
    expect { Date.iso8601(described_class::SITE_LAST_MODIFIED) }.not_to raise_error
    expect(Date.iso8601(described_class::SITE_LAST_MODIFIED)).to be <= Date.current
  end
end
