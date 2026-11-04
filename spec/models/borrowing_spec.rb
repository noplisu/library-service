require "rails_helper"

RSpec.describe Borrowing, type: :model do
  it "sets the due date 30 days after the loan starts" do
    borrowed_at = Time.zone.local(2026, 11, 3, 9)
    borrowing = build(:borrowing, borrowed_at: borrowed_at, due_on: nil)

    borrowing.validate

    expect(borrowing.due_on).to eq(Date.new(2026, 12, 3))
  end

  it "counts the due date on the Warsaw calendar when UTC is still the day before" do
    travel_to Time.find_zone("Europe/Warsaw").local(2026, 11, 4, 0, 30) do
      borrowing = build(:borrowing, borrowed_at: nil, due_on: nil)

      borrowing.validate

      expect(borrowing.due_on).to eq(Date.new(2026, 12, 4))
    end
  end

  it "allows only one open loan per book" do
    open_loan = create(:borrowing)
    another = build(:borrowing, book: open_loan.book)

    expect(another).not_to be_valid
    expect(another.errors[:book]).to include("is already borrowed")
  end

  it "records the return" do
    borrowing = create(:borrowing)

    travel_to Time.zone.local(2026, 11, 3, 9) do
      expect(borrowing.return!).to be(true)
      expect(borrowing.returned_at).to eq(Time.current)
    end
  end

  it "refuses a second return" do
    borrowing = create(:borrowing, :returned)

    expect(borrowing.return!).to be(false)
    expect(borrowing.errors[:returned_at]).to include("is already set")
  end

  it "allows a new loan after the previous one was returned" do
    returned = create(:borrowing, :returned)
    another = build(:borrowing, book: returned.book)

    expect(another).to be_valid
  end

  describe "row locks" do
    self.use_transactional_tests = false

    after do
      Borrowing.delete_all
      Book.delete_all
      Reader.delete_all
    end

    it "keeps a loan that took the book lock before deletion" do
      book = create(:book)
      reader = create(:reader)
      ready = Queue.new
      release = Queue.new
      lender = nil
      destroyer = nil

      begin
        lender = Thread.new do
          with_connection do
            Book.find(book.id).with_lock do
              ready << true
              release.pop
              Borrowing.new(book: Book.find(book.id), reader: Reader.find(reader.id)).lend
            end
          end
        end

        raise "lender did not take the book lock" unless ready.pop(timeout: 2)

        destroyer = Thread.new do
          with_connection { Book.find(book.id).destroy }
        end
        wait_until_a_lock_is_waiting
        release << true

        expect(lender.value).to be(true)
        expect(destroyer.value).to be(false)
        expect(Book.exists?(book.id)).to be(true)
        expect(Borrowing.where(book_id: book.id).count).to eq(1)
      ensure
        release << true
        lender&.join(2)
        destroyer&.join(2)
      end
    end

    it "does not lend a book deleted while the loan waits" do
      book = create(:book)
      reader = create(:reader)
      ready = Queue.new
      release = Queue.new
      deleter = nil
      lender = nil

      begin
        deleter = Thread.new do
          with_connection do
            Book.find(book.id).with_lock do
              ready << true
              release.pop
              Book.find(book.id).destroy
            end
          end
        end

        raise "deleter did not take the book lock" unless ready.pop(timeout: 2)

        lender = Thread.new do
          with_connection do
            borrowing = Borrowing.new(book: Book.find(book.id), reader: Reader.find(reader.id))
            [ borrowing.lend, borrowing.errors[:book] ]
          end
        end
        wait_until_a_lock_is_waiting
        release << true

        expect(deleter.value).to be_truthy
        lent, book_errors = lender.value
        expect(lent).to be(false)
        expect(book_errors).to include("must exist")
        expect(Book.exists?(book.id)).to be(false)
        expect(Borrowing.count).to eq(0)
      ensure
        release << true
        deleter&.join(2)
        lender&.join(2)
      end
    end

    it "does not lend to a reader deleted while the loan waits" do
      book = create(:book)
      reader = create(:reader)
      ready = Queue.new
      release = Queue.new
      hider = nil
      lender = nil

      begin
        hider = Thread.new do
          with_connection do
            Reader.find(reader.id).with_lock do
              ready << true
              release.pop
              Reader.find(reader.id).deactivate
            end
          end
        end

        raise "hider did not take the reader lock" unless ready.pop(timeout: 2)

        lender = Thread.new do
          with_connection do
            borrowing = Borrowing.new(book: Book.find(book.id), reader: Reader.find(reader.id))
            [ borrowing.lend, borrowing.errors[:reader] ]
          end
        end
        wait_until_a_lock_is_waiting
        release << true

        expect(hider.value).to be(true)
        lent, reader_errors = lender.value
        expect(lent).to be(false)
        expect(reader_errors).to include("must exist")
        expect(reader.reload.deleted_at).to be_present
        expect(Borrowing.count).to eq(0)
      ensure
        release << true
        hider&.join(2)
        lender&.join(2)
      end
    end

    def with_connection(&block)
      ActiveRecord::Base.connection_pool.with_connection(&block)
    end

    def wait_until_a_lock_is_waiting
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2
      loop do
        waiting = ActiveRecord::Base.connection.select_value(
          "SELECT COUNT(*) FROM pg_locks WHERE NOT granted"
        )
        return if waiting.to_i.positive?
        raise "timed out waiting for the row lock" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

        sleep 0.01
      end
    end
  end
end
