require "rails_helper"

RSpec.describe AgentsContent do
  describe ".markdown" do
    it "renders the /AGENTS.md prose body from config/agents.yml" do
      expect(described_class.markdown).to include(SeoConfig::MCP_ENDPOINT)
    end

    it "leaves no placeholder behind" do
      expect(described_class.markdown).not_to include("%{")
    end
  end

  describe ".llms_txt" do
    it "renders the /llms.txt link index, a different body from /AGENTS.md" do
      expect(described_class.llms_txt).to include(SeoConfig::MCP_ENDPOINT)
      expect(described_class.llms_txt).not_to eq(described_class.markdown)
    end

    it "leaves no placeholder behind" do
      expect(described_class.llms_txt).not_to include("%{")
    end
  end

  describe "interpolation" do
    it "substitutes every URL from SeoConfig, so none is hand-typed in the YAML" do
      config = {
        content: "%{site_url} %{mcp_endpoint} %{github_url} %{linkedin_url}",
        llms_content: "%{site_url}"
      }

      expect(described_class.markdown(config: config)).to eq(
        "#{SeoConfig::SITE_URL} #{SeoConfig::MCP_ENDPOINT} #{SeoConfig::GITHUB_URL} #{SeoConfig::LINKEDIN_URL}"
      )
      expect(described_class.llms_txt(config: config)).to eq(SeoConfig::SITE_URL)
    end

    it "raises on an unknown placeholder instead of serving a broken body" do
      expect { described_class.markdown(config: { content: "%{nope}" }) }.to raise_error(KeyError)
    end

    it "raises on a literal '%' in the YAML, which would otherwise be read as a placeholder" do
      expect { described_class.markdown(config: { content: "100% done" }) }.to raise_error(TypeError)
    end

    it "keeps the interpolation table private to this module" do
      expect { described_class.interpolate("anything") }.to raise_error(NoMethodError)
    end
  end
end
