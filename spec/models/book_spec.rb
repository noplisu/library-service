require "rails_helper"

RSpec.describe Book, type: :model do
  it "requires a six-digit serial number" do
    book = build(:book, serial_number: "42")

    expect(book).not_to be_valid
    expect(book.errors[:serial_number]).to be_present
  end

  it "rejects a duplicate serial number" do
    create(:book, serial_number: "000001")
    duplicate = build(:book, serial_number: "000001")

    expect(duplicate).not_to be_valid
  end

  it "reports borrowed while a loan is open" do
    borrowing = create(:borrowing)

    expect(borrowing.book.status).to eq("borrowed")
  end

  it "deletes the book and its history after the loan is returned" do
    borrowing = create(:borrowing, :returned)

    expect { borrowing.book.destroy }.to change(Book, :count).by(-1)
    expect(Borrowing.exists?(borrowing.id)).to be(false)
  end

  it "refuses deletion while a loan is open" do
    book = create(:borrowing).book

    expect(book.destroy).to be(false)
    expect(book.errors[:base]).to include("cannot be deleted while borrowed")
  end
end
