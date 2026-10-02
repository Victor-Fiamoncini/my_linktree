class SearchKnowledgeUseCase
  CANDIDATE_MULTIPLIER = 3

  def initialize(embedder: OpenaiEmbedder.new)
    @embedder = embedder
  end

  def execute(query:, limit: 8, per_source: 2)
    vector = @embedder.embed([ query ]).first
    counts = Hash.new(0)

    KnowledgeChunk.nearest_neighbors(:embedding, vector, distance: "cosine").first(limit * CANDIDATE_MULTIPLIER)
      .select { |chunk| (counts[chunk.title] += 1) <= per_source }
      .first(limit)
  end
end
