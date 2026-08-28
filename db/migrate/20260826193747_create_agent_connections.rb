class CreateAgentConnections < ActiveRecord::Migration[8.1]
  def change
    create_table :agent_connections do |t|
      t.string :tool, null: false

      t.timestamps
    end

    add_index :agent_connections, :created_at
  end
end
