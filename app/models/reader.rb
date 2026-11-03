class Reader < ApplicationRecord
  has_many :borrowings

  validates :full_name, presence: true
  validates :card_number, presence: true, uniqueness: true, format: { with: /\A\d{6}\z/ }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  before_destroy :reject_open_loan

  def to_param
    card_number
  end

  private
    def reject_open_loan
      if borrowings.exists?(returned_at: nil)
        errors.add(:base, "cannot be deleted while borrowing")
        throw :abort
      end

      borrowings.delete_all(:delete_all)
    end
end
