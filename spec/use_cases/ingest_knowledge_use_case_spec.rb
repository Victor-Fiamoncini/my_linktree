require "rails_helper"

RSpec.describe IngestKnowledgeUseCase do
  let(:embedder) { instance_double(OpenaiEmbedder) }
  let(:github) { instance_double(GithubReadmeClient) }
  let(:config) { { github_owner: "octo", repos: [ "alpha", "empty" ] } }
  let(:profile) do
    instance_double(GetProfileUseCase, execute: {
      name: "Victor",
      experiences: [
        { id: 1, company: "Acme", role: "Engineer", start_date: "2020-01", end_date: nil, current: true,
          country_name: "Brazil", backend: [ "Ruby" ], frontend: [], infra: [], other_tools: [], description: "Built things." },
        { id: 2, company: "Initech", role: "Intern", start_date: "2018-01", end_date: "2019-01", current: false,
          country_name: "Brazil", backend: [], frontend: [], infra: [], other_tools: [], description: "Learned things." }
      ],
      education: [ { institution: "IFC", degree: "Bachelor", field: "Computer Science" } ]
    })
  end
  let(:services) { instance_double(ListServicesUseCase, execute: [ { name: "Web", description: "Sites." } ]) }

  subject(:use_case) do
    described_class.new(embedder: embedder, github: github, profile: profile, services: services, config: config)
  end

  before do
    allow(github).to receive(:fetch).with(owner: "octo", repo: "alpha").and_return("# Alpha\n\nA Rails app.")
    allow(github).to receive(:fetch).with(owner: "octo", repo: "empty").and_return(nil)
    allow(embedder).to receive(:embed) { |texts| texts.each_index.map { |index| unit_vector(index) } }
  end

  it "embeds experiences, education, services and README chunks" do
    expect(use_case.execute).to eq(total: 5, embedded: 5, removed: 0)
    expect(embedder).to have_received(:embed).with(kind_of(Array))

    expect(KnowledgeChunk.pluck(:source_type)).to contain_exactly("experience", "experience", "education", "services", "github_readme")

    experience = KnowledgeChunk.find_by!(source_ref: "experience:1")
    expect(experience.title).to eq("Engineer at Acme")
    expect(experience.content).to include("2020-01 to present", "Backend: Ruby", "Built things.")
    expect(experience.content).not_to include("Frontend:")
    expect(KnowledgeChunk.find_by!(source_ref: "experience:2").content).to include("2018-01 to 2019-01")

    readme = KnowledgeChunk.find_by!(source_type: "github_readme")
    expect(readme).to have_attributes(source_ref: "alpha#0", title: "alpha", url: "https://github.com/octo/alpha")
    expect(readme.content).to eq("GitHub project alpha — Alpha\n\nA Rails app.")
  end

  it "re-embeds nothing when the sources haven't changed" do
    use_case.execute

    expect(use_case.execute).to eq(total: 5, embedded: 0, removed: 0)
    expect(embedder).to have_received(:embed).once
  end

  it "embeds only changed chunks and deletes the ones no source produces any more" do
    use_case.execute
    allow(github).to receive(:fetch).with(owner: "octo", repo: "alpha").and_return("# Alpha\n\nNow a Hanami app.")

    expect(use_case.execute).to eq(total: 5, embedded: 1, removed: 1)
    expect(KnowledgeChunk.find_by!(source_type: "github_readme").content).to include("Hanami")
  end

  it "replaces a chunk whose url changed even though its text didn't" do
    use_case.execute
    allow(github).to receive(:fetch).with(owner: "octo-org", repo: "alpha").and_return("# Alpha\n\nA Rails app.")
    allow(github).to receive(:fetch).with(owner: "octo-org", repo: "empty").and_return(nil)
    moved =described_class.new(embedder: embedder, github: github, profile: profile, services: services, config: config.merge(github_owner: "octo-org"))

    expect(moved.execute).to eq(total: 5, embedded: 1, removed: 1)
    expect(KnowledgeChunk.find_by!(source_type: "github_readme").url).to eq("https://github.com/octo-org/alpha")
  end
end
