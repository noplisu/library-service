# Idempotent sample catalog. One open loan is due in three days, so the daily reminder has a row to find.

[
  [ "000001", "Frankenstein", "Mary Shelley" ],
  [ "000002", "Pride and Prejudice", "Jane Austen" ],
  [ "000003", "The Left Hand of Darkness", "Ursula K. Le Guin" ],
  [ "000004", "The Dispossessed", "Ursula K. Le Guin" ]
].each do |serial_number, title, author|
  Book.find_or_create_by!(serial_number: serial_number) do |book|
    book.title = title
    book.author = author
  end
end

[
  [ "100001", "Ada Lovelace", "ada@library.test" ],
  [ "100002", "Grace Hopper", "grace@library.test" ],
  [ "100003", "Alan Turing", "alan@library.test" ]
].each do |card_number, full_name, email|
  Reader.find_or_create_by!(card_number: card_number) do |reader|
    reader.full_name = full_name
    reader.email = email
  end
end

due_soon = Book.find_by!(serial_number: "000001").borrowings.open.first_or_initialize
due_soon.reader = Reader.find_by!(card_number: "100001")
borrowed_on = Date.current - 27
due_soon.borrowed_at = Time.zone.local(borrowed_on.year, borrowed_on.month, borrowed_on.day, 10)
due_soon.due_on = Date.current + 3
due_soon.save!

current = Book.find_by!(serial_number: "000002").borrowings.open.first_or_initialize
if current.new_record?
  current.reader = Reader.find_by!(card_number: "100002")
  current.borrowed_at = Time.current
  current.save!
end
