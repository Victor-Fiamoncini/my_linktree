require "rails_helper"

RSpec.describe SearchKnowledgeUseCase do
  let(:embedder) { instance_double(OpenaiEmbedder) }

  it "embeds the query and returns the closest chunks first" do
    near = create_knowledge_chunk(axis: 0)
    middle = create_knowledge_chunk(axis: 1)
    create_knowledge_chunk(axis: 2)
    allow(embedder).to receive(:embed).with([ "Rails jobs" ])
      .and_return([ unit_vector(0).tap { |vector| vector[1] = 0.5 } ])

    expect(described_class.new(embedder: embedder).execute(query: "Rails jobs", limit: 2)).to eq([ near, middle ])
  end

  it "caps chunks per source, filling the freed slots with the next-closest sources" do
    alpha = Array.new(3) { |axis| create_knowledge_chunk(axis: axis, title: "alpha", content: "alpha #{axis}") }
    beta = create_knowledge_chunk(axis: 3, title: "beta")
    query = unit_vector(0).tap { |vector| vector[1] = 0.9; vector[2] = 0.8; vector[3] = 0.1 }
    allow(embedder).to receive(:embed).and_return([ query ])

    expect(described_class.new(embedder: embedder).execute(query: "Rails", limit: 3, per_source: 2)).to eq([ *alpha.first(2), beta ])
  end
end
