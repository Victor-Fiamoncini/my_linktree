require "rails_helper"

RSpec.describe GithubReadmeClient do
  let(:endpoint) { "https://api.github.com/repos/octo/repo/readme" }

  it "returns the raw README as UTF-8" do
    stub_request(:get, endpoint)
      .with(headers: { "Accept" => "application/vnd.github.raw+json" })
      .to_return(status: 200, body: "# Olá".b)

    readme = described_class.new(token: nil).fetch(owner: "octo", repo: "repo")

    expect(readme).to eq("# Olá")
    expect(readme.encoding).to eq(Encoding::UTF_8)
  end

  it "sends the token when one is configured" do
    stub = stub_request(:get, endpoint).with(headers: { "Authorization" => "Bearer gh-token" }).to_return(status: 200, body: "")

    described_class.new(token: "gh-token").fetch(owner: "octo", repo: "repo")

    expect(stub).to have_been_requested
  end

  it "returns nil when the repo has no README" do
    stub_request(:get, endpoint).to_return(status: 404)

    expect(described_class.new(token: nil).fetch(owner: "octo", repo: "repo")).to be_nil
  end

  # Raising rather than returning nil matters: ingestion treats nil as "README gone" and deletes
  # the repo's chunks, which a transient outage must not do.
  it "raises on any other failure" do
    stub_request(:get, endpoint).to_return(status: 503)

    expect { described_class.new(token: nil).fetch(owner: "octo", repo: "repo") }.to raise_error(GithubReadmeClient::Error, /HTTP 503/)
  end
end
