require "rails_helper"

RSpec.describe Borrowing, type: :model do
  it "sets the due date 30 days after the loan starts" do
    borrowed_at = Time.zone.local(2026, 11, 3, 9)
    borrowing = build(:borrowing, borrowed_at: borrowed_at, due_on: nil)

    borrowing.validate

    expect(borrowing.due_on).to eq(Date.new(2026, 12, 3))
  end

  it "allows only one open loan per book" do
    open_loan = create(:borrowing)
    another = build(:borrowing, book: open_loan.book)

    expect(another).not_to be_valid
    expect(another.errors[:book]).to include("is already borrowed")
  end

  it "allows a new loan after the previous one was returned" do
    returned = create(:borrowing, :returned)
    another = build(:borrowing, book: returned.book)

    expect(another).to be_valid
  end
end
