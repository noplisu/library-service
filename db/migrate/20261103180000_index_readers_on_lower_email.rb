class IndexReadersOnLowerEmail < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE readers SET email = lower(email)"

    remove_index :readers, name: "index_readers_on_email"
    add_index :readers, "lower(email)", unique: true, name: "index_readers_on_lower_email"
  end

  def down
    remove_index :readers, name: "index_readers_on_lower_email"
    add_index :readers, :email, unique: true, name: "index_readers_on_email"
  end
end
