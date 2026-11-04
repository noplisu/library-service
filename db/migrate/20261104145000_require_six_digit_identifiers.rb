class RequireSixDigitIdentifiers < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :books, "serial_number ~ '^[0-9]{6}$'", name: "books_serial_number_six_digits"
    add_check_constraint :readers, "card_number ~ '^[0-9]{6}$'", name: "readers_card_number_six_digits"
  end
end
