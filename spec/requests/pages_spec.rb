require "rails_helper"

RSpec.describe "Pages", type: :request do
  it "always redirects the bare root to /en, regardless of Accept-Language" do
    get "/"
    expect(response).to redirect_to("/en")

    get "/", headers: { "Accept-Language" => "pt-BR,pt;q=0.9" }
    expect(response).to redirect_to("/en")
  end

  it "renders the home page in English" do
    get "/en"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<!DOCTYPE html>")
    expect(response.body).to include('<html lang="en">')
  end

  it "renders the home page in Portuguese" do
    get "/pt-BR"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<html lang="pt-BR">')
  end

  # These render into <head>, so nothing on the page looks wrong when they break — a malformed
  # JSON-LD blob or an hreflang pointing at the wrong locale just quietly costs search ranking.
  describe "structured data and SEO tags" do
    let(:head) { Nokogiri::HTML(response.body).at("head") }

    it "emits a parseable JSON-LD graph linking the WebSite to the Person" do
      get "/en"

      graph = JSON.parse(head.at('script[type="application/ld+json"]').text).fetch("@graph")
      person = graph.find { |node| node["@type"] == "Person" }
      website = graph.find { |node| node["@type"] == "WebSite" }

      expect(person["name"]).to eq(SeoConfig::AUTHOR_NAME)
      expect(person["sameAs"]).to contain_exactly(SeoConfig::LINKEDIN_URL, SeoConfig::GITHUB_URL)
      expect(website.dig("author", "@id")).to eq(person["@id"])
    end

    it "points each hreflang at its own locale's path, not the requested one" do
      get "/pt-BR"

      alternates = head.css('link[rel="alternate"]').to_h { |link| [ link["hreflang"], link["href"] ] }

      expect(alternates).to eq(
        "en" => "#{SeoConfig::SITE_URL}/en",
        "pt-BR" => "#{SeoConfig::SITE_URL}/pt-BR",
        "x-default" => "#{SeoConfig::SITE_URL}/en"
      )
    end

    it "canonicalizes to the requested locale's absolute URL" do
      get "/pt-BR"

      expect(head.at('link[rel="canonical"]')["href"]).to eq("#{SeoConfig::SITE_URL}/pt-BR")
    end
  end
end
