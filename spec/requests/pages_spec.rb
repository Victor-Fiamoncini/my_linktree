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
end
