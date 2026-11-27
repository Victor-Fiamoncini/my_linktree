class DropOrphanedSolidCacheEntriesFromPrimary < ActiveRecord::Migration[8.1]
  def change
    # if_exists: a fresh database never had the table (it only lived in primary before the cache
    # moved to its own database), so the drop must be a no-op there rather than abort every later migration
    drop_table :solid_cache_entries, if_exists: true do |t|
      t.binary :key, null: false, limit: 1024
      t.binary :value, null: false, limit: 512.megabytes
      t.datetime :created_at, null: false
      t.bigint :key_hash, null: false
      t.integer :byte_size, null: false

      t.index :byte_size
      t.index :key_hash, unique: true
      t.index [ :key_hash, :byte_size ]
    end
  end
end
