class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :company
      t.datetime :slot_start, null: false

      t.timestamps
    end

    add_index :bookings, :slot_start, unique: true
  end
end
