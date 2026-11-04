class BooksController < ApplicationController
  before_action :set_book, only: %i[ show destroy ]

  def index
    books, meta = paginate(Book.order(:serial_number).preload(open_borrowing: :reader))

    render json: {
      books: books.map { |book| book_summary(book) },
      **meta
    }
  end

  def show
    render json: book_summary(@book).merge(
      borrowings: @book.borrowings.includes(:reader).order(:borrowed_at).map(&:as_api_json)
    )
  end

  def create
    book = Book.new(book_params)

    if book.save
      render json: book_summary(book), status: :created
    else
      render json: book.errors, status: :unprocessable_content
    end
  end

  def destroy
    if @book.destroy
      head :no_content
    else
      render json: @book.errors, status: :unprocessable_content
    end
  end

  private
    def set_book
      @book = Book.preload(open_borrowing: :reader).find_by!(serial_number: params[:serial_number])
    end

    def book_params
      params.expect(book: %i[ serial_number title author ])
    end

    def book_summary(book)
      {
        serial_number: book.serial_number,
        title: book.title,
        author: book.author,
        status: book.status,
        current_borrowing: book.open_borrowing&.as_current_json
      }
    end
end
