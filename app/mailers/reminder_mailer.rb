class ReminderMailer < ApplicationMailer
  def due_date(borrowing, on:)
    @borrowing = borrowing
    @book = borrowing.book
    @reader = borrowing.reader
    @due_phrase = due_phrase(borrowing.due_on, on)

    mail(
      to: @reader.email,
      subject: "Book due #{@due_phrase}: #{@book.title}"
    )
  end

  private
    def due_phrase(due_on, on)
      days_left = (due_on - on).to_i
      days_left.zero? ? "today" : "in #{days_left} days"
    end
end
