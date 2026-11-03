class Reader < ApplicationRecord
  has_many :borrowings

  scope :active, -> { where(deleted_at: nil) }

  before_validation :normalize_email

  validates :full_name, presence: true
  validates :card_number, presence: true, uniqueness: true, format: { with: /\A\d{6}\z/ }
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }

  def to_param
    card_number
  end

  def deactivate
    with_lock do
      open_loans = borrowings.open.count
      if open_loans.positive?
        noun = "book".pluralize(open_loans)
        verb = open_loans == 1 ? "is" : "are"
        errors.add(:base, "cannot be deleted while #{open_loans} #{noun} #{verb} still borrowed")
        false
      else
        update(deleted_at: Time.current)
      end
    end
  end

  private
    def normalize_email
      self.email = email.downcase if email.present?
    end
end
