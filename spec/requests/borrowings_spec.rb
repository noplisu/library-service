require "rails_helper"

RSpec.describe "/borrowings", type: :request do
  describe "POST /borrowings" do
    it "lends the book for 30 days" do
      book = create(:book)
      reader = create(:reader)

      travel_to Time.zone.local(2026, 11, 3, 9) do
        post borrowings_url, params: {
          borrowing: { serial_number: book.serial_number, card_number: reader.card_number }
        }, as: :json
      end

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["due_on"]).to eq("2026-12-03")
      expect(response.parsed_body["returned_at"]).to be_nil
      expect(book.reload.status).to eq("borrowed")
    end

    it "rejects a loan when the book is already out" do
      borrowing = create(:borrowing)
      reader = create(:reader)

      expect {
        post borrowings_url, params: {
          borrowing: { serial_number: borrowing.book.serial_number, card_number: reader.card_number }
        }, as: :json
      }.not_to change(Borrowing, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects an unknown reader" do
      book = create(:book)

      post borrowings_url, params: {
        borrowing: { serial_number: book.serial_number, card_number: "999999" }
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /borrowings/:id" do
    it "marks the book returned" do
      borrowing = create(:borrowing)

      patch borrowing_url(borrowing), as: :json

      expect(response).to have_http_status(:ok)
      expect(borrowing.reload.returned_at).to be_present
      expect(borrowing.book.status).to eq("available")
    end

    it "rejects a second return" do
      borrowing = create(:borrowing, :returned)

      patch borrowing_url(borrowing), as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
