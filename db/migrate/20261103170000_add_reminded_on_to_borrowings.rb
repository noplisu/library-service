class AddRemindedOnToBorrowings < ActiveRecord::Migration[8.1]
  def change
    add_column :borrowings, :reminded_on, :date
  end
end
