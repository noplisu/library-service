class DueDateRemindersJob < ApplicationJob
  def perform(on = Date.current)
    Borrowing.due_for_reminder(on).preload(:book, :reader).find_each do |borrowing|
      ReminderMailer.due_date(borrowing, on: on).deliver_now
      borrowing.update!(reminded_on: on)
    end
  end
end
