class CreateBorrowings < ActiveRecord::Migration[8.1]
  def change
    create_table :borrowings do |t|
      t.references :book, null: false, foreign_key: true
      t.references :reader, null: false, foreign_key: true
      t.datetime :borrowed_at, null: false
      t.date :due_on, null: false
      t.datetime :returned_at

      t.timestamps
    end

    add_index :borrowings, :book_id,
          unique: true,
          where: "returned_at IS NULL",
          name: "index_borrowings_one_open_loan_per_book"

    add_index :borrowings, :due_on,
          where: "returned_at IS NULL",
          name: "index_borrowings_open_due_on"
  end
end
