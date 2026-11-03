require "rails_helper"

RSpec.describe DueDateRemindersJob, type: :job do
  around do |example|
    travel_to(Time.zone.local(2026, 11, 3, 7)) { example.run }
  end

  before { ActionMailer::Base.deliveries.clear }

  it "reminds the reader three days before the due date" do
    borrowing = create(:borrowing, due_on: Date.new(2026, 11, 6))

    described_class.perform_now

    mail = ActionMailer::Base.deliveries.sole
    expect(mail.to).to eq([ borrowing.reader.email ])
    expect(mail.subject).to eq("Book due in 3 days: #{borrowing.book.title}")
    expect(mail.body.encoded).to include(borrowing.book.serial_number, "2026-11-06")
  end

  it "reminds the reader on the due date" do
    borrowing = create(:borrowing, due_on: Date.new(2026, 11, 3))

    described_class.perform_now

    mail = ActionMailer::Base.deliveries.sole
    expect(mail.to).to eq([ borrowing.reader.email ])
    expect(mail.subject).to eq("Book due today: #{borrowing.book.title}")
    expect(mail.body.encoded).to include(borrowing.book.serial_number, "2026-11-03")
  end

  it "skips a loan that is due on another day" do
    create(:borrowing, due_on: Date.new(2026, 11, 5))

    described_class.perform_now

    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "logs one email per loan when it runs twice the same day" do
    due_soon = create(:borrowing, due_on: Date.new(2026, 11, 6))
    due_today = create(:borrowing, due_on: Date.new(2026, 11, 3))
    logged = []
    allow(Rails.logger).to receive(:info) do |message|
      logged << message if message.to_s.start_with?("Reminder email")
    end

    original = ActionMailer::Base.delivery_method
    ActionMailer::Base.delivery_method = :log
    described_class.perform_now
    described_class.perform_now
  ensure
    ActionMailer::Base.delivery_method = original

    expect(logged.map { |line| line[/to=(\S+)/, 1] }).to contain_exactly(
      due_soon.reader.email,
      due_today.reader.email
    )
  end

  it "skips a loan that has already been returned" do
    create(:borrowing, :returned, due_on: Date.new(2026, 11, 3))

    described_class.perform_now

    expect(ActionMailer::Base.deliveries).to be_empty
  end
end
