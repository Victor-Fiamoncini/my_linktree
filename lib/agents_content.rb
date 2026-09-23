module AgentsContent
  def self.markdown(config: Rails.application.config_for(:agents))
    interpolate(config[:content])
  end

  def self.llms_txt(config: Rails.application.config_for(:agents))
    interpolate(config[:llms_content])
  end

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
