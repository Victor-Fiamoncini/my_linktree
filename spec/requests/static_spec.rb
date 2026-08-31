require "rails_helper"

RSpec.describe "Static", type: :request do
  it "returns the sitemap as XML" do
    get "/sitemap.xml"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/xml")
  end

  it "returns AGENTS.md as markdown" do
    get "/AGENTS.md"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/markdown")
    expect(response.body).to include("hire Victor Fiamoncini")
  end

  it "returns llms.txt with the same content as AGENTS.md" do
    get "/llms.txt"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("hire Victor Fiamoncini")
  end
end
