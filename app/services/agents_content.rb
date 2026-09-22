module AgentsContent
  # /AGENTS.md — prose instructions.
  def self.markdown(config: Rails.application.config_for(:agents))
    interpolate(config[:content])
  end

  # /llms.txt — the same surface as a link index, in the llmstxt.org shape.
  def self.llms_txt(config: Rails.application.config_for(:agents))
    interpolate(config[:llms_content])
  end

  # One table for both bodies, so a URL is never written out by hand in config/agents.yml.
  def self.interpolate(body)
    body % {
      site_url: SeoConfig::SITE_URL,
      mcp_endpoint: SeoConfig::MCP_ENDPOINT,
      github_url: SeoConfig::GITHUB_URL,
      linkedin_url: SeoConfig::LINKEDIN_URL
    }
  end

  private_class_method :interpolate
end
