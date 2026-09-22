require "rails_helper"

RSpec.describe "Static", type: :request do
  it "returns the sitemap as XML" do
    get "/sitemap.xml"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/xml")
  end

  it "lists both locales in the sitemap" do
    get "/sitemap.xml"

    expect(response.body).to include("<loc>https://www.victorfiamon.com.br/en</loc>")
    expect(response.body).to include("<loc>https://www.victorfiamon.com.br/pt-BR</loc>")
  end

  it "returns AGENTS.md as markdown" do
    get "/AGENTS.md"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/markdown")
    expect(response.body).to include("hire Victor Fiamoncini")
  end

  it "returns llms.txt in the llmstxt.org shape" do
    get "/llms.txt"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/plain")
    expect(response.body).to start_with("# Victor Fiamoncini\n\n> ")
  end

  it "does not serve the AGENTS.md prose at llms.txt" do
    get "/llms.txt"

    expect(response.body).not_to include("# AGENTS.md")
  end

  # Both bodies are hand-written, so nothing stops either drifting from the app they describe.
  # These are the things that notice.
  %w[/AGENTS.md /llms.txt].each do |path|
    context "#{path} as a description of this app" do
      it "points at the MCP endpoint and the hire endpoint" do
        get path

        expect(response.body).to include(SeoConfig::MCP_ENDPOINT)
        expect(response.body).to include("#{SeoConfig::SITE_URL}/api/hire")
      end

      it "names every tool the MCP server registers" do
        get path

        Api::McpController::TOOLS.each do |tool|
          expect(response.body).to include(tool.tool_name)
        end
      end

      # Not just GET: /api/hire is POST-only and /api/mcp answers four verbs. What matters is
      # that an advertised URL isn't a 404 for everyone (telemetry, say, is locale-scoped, so a
      # bare /telemetry routes nowhere).
      it "only links this site's URLs that actually route" do
        get path

        response.body.scan(%r{#{Regexp.escape(SeoConfig::SITE_URL)}(/[\w\-./]*)}).flatten.each do |url_path|
          routable = %i[get post delete options].any? do |verb|
            Rails.application.routes.recognize_path(url_path, method: verb)
            true
          rescue ActionController::RoutingError
            false
          end

          expect(routable).to be(true), "#{path} advertises #{url_path}, which matches no route"
        end
      end
    end
  end
end
