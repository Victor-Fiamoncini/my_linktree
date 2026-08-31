module AgentsContent
  def self.markdown(config: Rails.application.config_for(:agents))
    config[:content] % { site_url: SeoConfig::SITE_URL }
  end
end
