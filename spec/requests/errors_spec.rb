require "rails_helper"

RSpec.describe "Errors", type: :request do
  # Test shows the debug page and re-raises non-rescuable errors; production does neither.
  around do |example|
    env_config = Rails.application.env_config
    original = env_config.slice("action_dispatch.show_detailed_exceptions", "action_dispatch.show_exceptions")
    env_config.merge!("action_dispatch.show_detailed_exceptions" => false, "action_dispatch.show_exceptions" => :all)
    example.run
  ensure
    env_config.merge!(original)
  end

  let(:page) { Nokogiri::HTML(response.body) }

  it "renders the English 404 page under /en" do
    get "/en/nope"

    expect(response).to have_http_status(:not_found)
    expect(response.media_type).to eq("text/html")
    expect(response.body).to include('<html lang="en">')
    expect(page.at("h1").text).to eq(I18n.t("errors.not_found.heading", locale: :en))
  end

  it "renders the Portuguese 404 page under /pt-BR" do
    get "/pt-BR/nope"

    expect(response).to have_http_status(:not_found)
    expect(response.body).to include('<html lang="pt-BR">')
    expect(page.at("h1").text).to eq(I18n.t("errors.not_found.heading", locale: :"pt-BR"))
  end

  it "detects the locale from CF-IPCountry for a path without one" do
    get "/nope", headers: { "CF-IPCountry" => "BR" }

    expect(response.body).to include('<html lang="pt-BR">')
    expect(page.at('link[rel="canonical"]')["href"]).to eq("#{SeoConfig::SITE_URL}/pt-BR/nope")
  end

  it "detects the locale from Accept-Language for a path without one" do
    get "/nope", headers: { "Accept-Language" => "en-US,en;q=0.9" }

    expect(response.body).to include('<html lang="en">')
  end

  it "points the language switch at the same path in the other locale" do
    get "/en/nope"

    expect(page.at('header a[hreflang="pt-BR"]')["href"]).to eq("/pt-BR/nope")
  end

  it "is noindex and never cached" do
    get "/en/nope"

    expect(page.at('meta[name="robots"]')["content"]).to eq("noindex, nofollow")
    expect(response.headers["Cache-Control"]).to include("no-store")
  end

  it "answers unknown API paths with JSON, whatever the verb" do
    get "/api/nope"

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body).to eq("message" => "Not Found")

    post "/api/nope"

    expect(response).to have_http_status(:not_found)
    expect(response.media_type).to eq("application/json")
  end

  it "tags events with the missing URL, not the rewritten /404" do
    allow(Rails.event).to receive(:set_context).and_call_original

    get "/en/nope"

    expect(Rails.event).to have_received(:set_context).with(path: "/en/nope")
  end

  it "falls back to public/404.html and reports the error when the page itself fails" do
    allow(Rails.error).to receive(:report)
    allow(ErrorsController).to receive(:action).with(:not_found).and_return(->(_env) { raise StandardError, "boom" })

    get "/en/nope"

    expect(response).to have_http_status(:not_found)
    expect(response.body).to include("(404 Not found)")
    expect(Rails.error).to have_received(:report).with(an_instance_of(StandardError), handled: true, source: "errors_controller")
  end

  it "still serves other statuses from public/" do
    allow(GetProfileUseCase).to receive(:new).and_raise(StandardError)

    get "/en"

    expect(response).to have_http_status(:internal_server_error)
    expect(response.body).to include("500 Internal Server Error")
  end
end
