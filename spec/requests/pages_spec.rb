require "rails_helper"

RSpec.describe "Pages", type: :request do
  it "renders the home page" do
    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<!DOCTYPE html>")
  end
end
