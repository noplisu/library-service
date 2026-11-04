require "rails_helper"

RSpec.describe Reader, type: :model do
  it "requires a six-digit card number and an email" do
    reader = build(:reader, card_number: "12345", email: "not-an-email")

    expect(reader).not_to be_valid
    expect(reader.errors[:card_number]).to be_present
    expect(reader.errors[:email]).to be_present
  end

  it "rejects a card number of letters in the database" do
    expect {
      Reader.insert_all!([ { card_number: "abc", full_name: "Ada Lovelace", email: "ada@library.test", created_at: Time.current, updated_at: Time.current } ])
    }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "rejects a duplicate email regardless of case" do
    create(:reader, email: "ada@library.test")
    duplicate = build(:reader, email: "Ada@library.test")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:email]).to include("has already been taken")
  end

  it "stores the email in lowercase" do
    reader = create(:reader, email: "Ada@Library.test")

    expect(reader.reload.email).to eq("ada@library.test")
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
