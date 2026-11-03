require "rails_helper"

RSpec.describe "/readers", type: :request do
  describe "GET /readers" do
    it "lists one page of readers" do
      create_list(:reader, 2)

      get readers_url, params: { per_page: 1 }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["readers"].size).to eq(1)
      expect(response.parsed_body["per_page"]).to eq(1)
      expect(response.parsed_body["total_count"]).to eq(2)
      expect(response.parsed_body["total_pages"]).to eq(2)
    end
  end

  describe "POST /readers" do
    it "creates a reader" do
      expect {
        post readers_url, params: {
          reader: { card_number: "000010", full_name: "Grace Hopper", email: "grace@library.test" }
        }, as: :json
      }.to change(Reader, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["card_number"]).to eq("000010")
    end

    it "rejects a duplicate email" do
      create(:reader, email: "ada@library.test")

      expect {
        post readers_url, params: {
          reader: { card_number: "000011", full_name: "Ada Lovelace", email: "ada@library.test" }
        }, as: :json
      }.not_to change(Reader, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /readers/:card_number" do
    it "updates the reader" do
      reader = create(:reader)

      patch reader_url(reader), params: { reader: { full_name: "Grace Hopper" } }, as: :json

      expect(response).to have_http_status(:ok)
      expect(reader.reload.full_name).to eq("Grace Hopper")
    end
  end

  describe "DELETE /readers/:card_number" do
    it "deletes a reader without an open loan" do
      reader = create(:reader)

      expect { delete reader_url(reader), as: :json }.to change(Reader, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "refuses to delete a reader who still has a book" do
      reader = create(:borrowing).reader

      expect { delete reader_url(reader), as: :json }.not_to change(Reader, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
