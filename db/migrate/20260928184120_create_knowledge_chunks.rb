class CreateKnowledgeChunks < ActiveRecord::Migration[8.1]
  def change
    create_table :knowledge_chunks do |t|
      t.string :source_type, null: false
      t.string :source_ref, null: false
      t.string :title, null: false
      t.string :url
      t.text :content, null: false
      t.string :content_hash, null: false
      t.vector :embedding, limit: 1024, null: false

      t.timestamps
    end

    add_index :knowledge_chunks, :content_hash, unique: true
    add_index :knowledge_chunks, :embedding, using: :hnsw, opclass: :vector_cosine_ops
  end
end
