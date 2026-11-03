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

  it "keeps returned loans when the reader is deleted" do
    borrowing = create(:borrowing, :returned)
    reader = borrowing.reader

    expect(reader.deactivate).to be(true)

    expect(reader.reload.deleted_at).to be_present
    expect(borrowing.reload.reader).to eq(reader)
  end

  it "refuses deletion while the reader has an open loan" do
    reader = create(:borrowing).reader

    expect(reader.deactivate).to be(false)
    expect(reader.reload.deleted_at).to be_nil
    expect(reader.errors[:base]).to include("cannot be deleted while 1 book is still borrowed")
  end
end
