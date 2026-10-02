class KnowledgeChunk < ApplicationRecord
  has_neighbors :embedding

  validates :source_type, :source_ref, :title, :content, :content_hash, :embedding, presence: true
end
