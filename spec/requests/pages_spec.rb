require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "the bare root" do
    it "sends visitors Cloudflare places in Brazil to /pt-BR" do
      get "/", headers: { "CF-IPCountry" => "BR" }

      expect(response).to redirect_to("/pt-BR")
      expect(response).to have_http_status(:found)
    end

    it "sends everyone else to /en, even with a Portuguese Accept-Language" do
      get "/", headers: { "CF-IPCountry" => "US", "Accept-Language" => "pt-BR,pt;q=0.9" }

      expect(response).to redirect_to("/en")
    end

    it "falls back to Accept-Language when there is no country header" do
      get "/", headers: { "Accept-Language" => "pt-BR,pt;q=0.9" }

      expect(response).to redirect_to("/pt-BR")
    end

    it "defaults to /en with no signals at all" do
      get "/"

      expect(response).to redirect_to("/en")
    end

    it "carries the query string across, so campaign params survive the hop" do
      get "/?utm_source=newsletter&utm_medium=email", headers: { "CF-IPCountry" => "BR" }

      expect(response).to redirect_to("/pt-BR?utm_source=newsletter&utm_medium=email")
    end

    # Header bytes aren't validated as UTF-8 anywhere upstream, and ApplicationController has no
    # rescue_from — an unscrubbed header raised straight out of here as a 500 on the root URL.
    it "redirects rather than 500s on headers that aren't valid UTF-8" do
      get "/", headers: { "Accept-Language" => "pt\xFF\xFE" }
      expect(response).to redirect_to("/pt-BR")

      get "/", headers: { "CF-IPCountry" => "B\xFFR", "Accept-Language" => "pt-BR" }
      expect(response).to redirect_to("/en")
    end

    # A cached redirect would serve one visitor's language to the next.
    it "forbids caching, since the target varies per visitor" do
      get "/", headers: { "CF-IPCountry" => "BR" }

      expect(response.headers["Cache-Control"]).to eq("private, no-store")
      expect(response.headers["Vary"]).to be_nil
    end
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
