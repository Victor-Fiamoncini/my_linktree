module KnowledgeHelpers
  # A unit vector along one axis, so cosine distances in specs are easy to reason about.
  def unit_vector(axis, dimensions: 1024)
    Array.new(dimensions, 0.0).tap { |vector| vector[axis] = 1.0 }
  end

  def create_knowledge_chunk(axis:, title: "Chunk #{axis}", url: "https://example.com/#{axis}", content: "Content #{axis}")
    KnowledgeChunk.create!(
      source_type: "github_readme",
      source_ref: "repo##{axis}",
      title: title,
      url: url,
      content: content,
      content_hash: Digest::SHA256.hexdigest(content),
      embedding: unit_vector(axis)
    )
  end
end

RSpec.configure do |config|
  config.include KnowledgeHelpers
end
