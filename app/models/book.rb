class Book < ApplicationRecord
  has_many :borrowings
  has_one :open_borrowing, -> { where(returned_at: nil) }, class_name: "Borrowing"

  validates :title, :author, presence: true
  validates :serial_number, presence: true, uniqueness: true, format: { with: /\A\d{6}\z/ }

  before_destroy :reject_open_loan

  def status
    open_borrowing.present? ? "borrowed" : "available"
  end

  def to_param
    serial_number
  end

  private
    def reject_open_loan
      if open_borrowing.present?
        errors.add(:base, "cannot be deleted while borrowed")
        throw :abort
      end

      borrowings.delete_all(:delete_all)
    end
end
