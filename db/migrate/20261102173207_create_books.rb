class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.string :serial_number, limit: 6, null: false
      t.string :title, null: false
      t.string :author, null: false

      t.timestamps
    end
    add_index :books, :serial_number, unique: true
  end
end
