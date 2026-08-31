module AgentsContent
  CONTENT = <<~MARKDOWN
    # AGENTS.md — hire Victor Fiamoncini

    To contact me directly:
    POST #{SeoConfig::SITE_URL}/api/hire
    Content-Type: application/json

    {
      "name": "Your name",
      "contact": "email or preferred channel",
      "brief": "What you want to discuss",
      "agent": "chatgpt | claude | kimi | other"
    }

    Services: Frontend & Backend Software Development, Agentic Systems & Integrations, Websites & Landing Pages and Mobile Apps
  MARKDOWN
end
