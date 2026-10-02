require "rails_helper"

RSpec.describe KnowledgeChunk do
  it "requires the fields retrieval depends on" do
    chunk = described_class.new

    expect(chunk).not_to be_valid
    expect(chunk.errors.attribute_names).to include(:source_type, :source_ref, :title, :content, :content_hash, :embedding)
  end

  it "orders nearest neighbours by cosine distance" do
    far = create_knowledge_chunk(axis: 1)
    near = create_knowledge_chunk(axis: 0)

    expect(described_class.nearest_neighbors(:embedding, unit_vector(0), distance: "cosine").first(2)).to eq([ near, far ])
  end
end
