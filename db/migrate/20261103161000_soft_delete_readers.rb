class SoftDeleteReaders < ActiveRecord::Migration[8.1]
  def change
    add_column :readers, :deleted_at, :datetime

    remove_index :readers, :card_number
    remove_index :readers, :email
    add_index :readers, :card_number, unique: true
    add_index :readers, :email, unique: true
  end
end
