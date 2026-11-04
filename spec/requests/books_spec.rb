require "rails_helper"

RSpec.describe "/books", type: :request do
  describe "GET /books" do
    it "lists one page of books with availability" do
      available = create_list(:book, 2)
      borrowed = create(:book)
      loan = create(:borrowing, book: borrowed)

      get books_url, params: { per_page: 2 }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["page"]).to eq(1)
      expect(body["per_page"]).to eq(2)
      expect(body["total_count"]).to eq(3)
      expect(body["total_pages"]).to eq(2)
      expect(body["books"].map { |book| book["serial_number"] }).to eq(available.map(&:serial_number))
      expect(body["books"].map { |book| book["status"] }).to all(eq("available"))
      expect(body["books"].map { |book| book["current_borrowing"] }).to all(be_nil)

      get books_url, params: { page: 2, per_page: 2 }

      second_page = response.parsed_body["books"]
      expect(second_page.size).to eq(1)
      current = second_page.first
      expect(current["serial_number"]).to eq(borrowed.serial_number)
      expect(current["status"]).to eq("borrowed")
      expect(current["current_borrowing"]).to include(
        "due_on" => loan.due_on.as_json,
        "reader" => {
          "card_number" => loan.reader.card_number,
          "full_name" => loan.reader.full_name,
          "email" => loan.reader.email
        }
      )
      expect(current["current_borrowing"]["borrowed_at"]).to eq(loan.borrowed_at.as_json)
    end

    it "preloads the open loan and its reader for the page" do
      create_list(:book, 2)
      create(:borrowing)

      queries = []
      callback = lambda do |_name, _start, _finish, _id, payload|
        queries << payload[:sql] unless payload[:name].in?(%w[SCHEMA TRANSACTION])
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get books_url
      end

      expect(queries.size).to eq(4)
    end

    it "caps the page size at 100" do
      create(:book)

      get books_url, params: { per_page: 500 }

      expect(response.parsed_body["per_page"]).to eq(100)
    end
  end

  describe "GET /books/:serial_number" do
    it "returns JSON when the book does not exist" do
      get book_url("000000")

      expect(response).to have_http_status(:not_found)
      expect(response.media_type).to eq("application/json")
      expect(response.parsed_body["error"]).to eq("Not found")
    end

    it "returns the book with its borrowing history" do
      book = create(:book)
      reader = create(:reader)
      create(:borrowing, :returned, book: book, reader: reader, borrowed_at: 40.days.ago)
      create(:borrowing, book: book, reader: reader)

      get book_url(book), as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["serial_number"]).to eq(book.serial_number)
      expect(body["status"]).to eq("borrowed")
      expect(body["current_borrowing"]["reader"]["card_number"]).to eq(reader.card_number)
      expect(body["current_borrowing"]["due_on"]).to eq(book.borrowings.open.sole.due_on.as_json)
      expect(body["borrowings"].size).to eq(2)
      expect(body["borrowings"].last["returned_at"]).to be_nil
      expect(body["borrowings"].last["reader"]["card_number"]).to eq(reader.card_number)
    end

    it "keeps both returned loans after the reader is deleted" do
      book = create(:book)
      reader = create(:reader)
      create(:borrowing, :returned, book: book, reader: reader, borrowed_at: 40.days.ago)
      create(:borrowing, :returned, book: book, reader: reader, borrowed_at: 10.days.ago)

      delete reader_url(reader), as: :json

      expect(response).to have_http_status(:no_content)

      get book_url(book), as: :json

      history = response.parsed_body["borrowings"]
      expect(history.size).to eq(2)
      expect(history.map { |entry| entry["reader"] }).to all(eq(
        "card_number" => reader.card_number,
        "full_name" => reader.full_name,
        "email" => reader.email
      ))
    end
  end

  describe "POST /books" do
    it "creates a book" do
      expect {
        post books_url, params: {
          book: { serial_number: "000042", title: "Dune", author: "Frank Herbert" }
        }, as: :json
      }.to change(Book, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["status"]).to eq("available")
      expect(response.parsed_body["current_borrowing"]).to be_nil
    end

    it "rejects a missing book parameter" do
      post books_url, params: {}, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["error"]).to include("book")
    end

    it "rejects a serial number lost to a concurrent create" do
      allow_any_instance_of(Book).to receive(:save).and_raise(
        ActiveRecord::RecordNotUnique.new(
          'duplicate key value violates unique constraint "index_books_on_serial_number"'
        )
      )

      expect {
        post books_url, params: {
          book: { serial_number: "000042", title: "Dune", author: "Frank Herbert" }
        }, as: :json
      }.not_to change(Book, :count)

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error"]).to eq("Record already exists or book is already borrowed")
    end

    it "rejects a serial number that is not six digits" do
      expect {
        post books_url, params: {
          book: { serial_number: "42", title: "Dune", author: "Frank Herbert" }
        }, as: :json
      }.not_to change(Book, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /books/:serial_number" do
    it "deletes an available book" do
      book = create(:book)

      expect { delete book_url(book), as: :json }.to change(Book, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "refuses to delete a borrowed book" do
      book = create(:borrowing).book

      expect { delete book_url(book), as: :json }.not_to change(Book, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
