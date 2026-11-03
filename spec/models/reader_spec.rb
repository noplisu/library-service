require "rails_helper"

RSpec.describe Reader, type: :model do
  it "requires a six-digit card number and an email" do
    reader = build(:reader, card_number: "12345", email: "not-an-email")

    expect(reader).not_to be_valid
    expect(reader.errors[:card_number]).to be_present
    expect(reader.errors[:email]).to be_present
  end

  it "rejects a duplicate email" do
    create(:reader, email: "ada@library.test")
    duplicate = build(:reader, email: "ada@library.test")

    expect(duplicate).not_to be_valid
  end

  it "deletes the reader and their history after the loan is returned" do
    borrowing = create(:borrowing, :returned)

    expect { borrowing.reader.destroy }.to change(Reader, :count).by(-1)
    expect(Borrowing.exists?(borrowing.id)).to be(false)
  end

  it "refuses deletion while the reader has an open loan" do
    reader = create(:borrowing).reader

    expect(reader.destroy).to be(false)
  end
end
