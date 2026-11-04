class Borrowing < ApplicationRecord
  LOAN_PERIOD_DAYS = 30
  REMINDER_LEAD_DAYS = 3

  belongs_to :book
  belongs_to :reader

  scope :open, -> { where(returned_at: nil) }

  validates :borrowed_at, :due_on, presence: true
  validate :book_is_available, on: :create

  before_validation :assign_loan_period, on: :create

  def self.due_for_reminder(on = Date.current)
    open
      .where(due_on: [ on, on + REMINDER_LEAD_DAYS ])
      .where("reminded_on IS NULL OR reminded_on <> ?", on)
  end

  def lend
    return save unless book

    book.with_lock { lend_to_reader }
  rescue ActiveRecord::RecordNotFound
    errors.add(:book, :required)
    false
  rescue ActiveRecord::RecordNotUnique
    reject_already_borrowed
  end

  def return!
    with_lock do
      if returned_at?
        errors.add(:returned_at, "is already set")
        false
      else
        update(returned_at: Time.current)
      end
    end
  end

  def as_api_json
    {
      id: id,
      borrowed_at: borrowed_at,
      due_on: due_on,
      returned_at: returned_at,
      reader: reader.as_api_json
    }
  end

  def as_current_json
    {
      borrowed_at: borrowed_at,
      due_on: due_on,
      reader: reader.as_api_json
    }
  end

  private
    def lend_to_reader
      return save unless reader

      reader.with_lock do
        if reader.deleted_at?
          errors.add(:reader, :required)
          false
        else
          save
        end
      end
    end

    def assign_loan_period
      self.borrowed_at ||= Time.current
      self.due_on ||= borrowed_at.in_time_zone.to_date + LOAN_PERIOD_DAYS
    end

    def book_is_available
      return if book.blank?
      return unless book.borrowings.open.where.not(id: id).exists?

      reject_already_borrowed
    end

    def reject_already_borrowed
      errors.add(:book, "is already borrowed")
      false
    end
end
