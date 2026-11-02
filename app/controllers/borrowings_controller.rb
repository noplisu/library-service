class BorrowingsController < ApplicationController
  before_action :set_borrowing, only: %i[ show update destroy ]

  # GET /borrowings
  def index
    @borrowings = Borrowing.all

    render json: @borrowings
  end

  # GET /borrowings/1
  def show
    render json: @borrowing
  end

  # POST /borrowings
  def create
    @borrowing = Borrowing.new(borrowing_params)

    if @borrowing.save
      render json: @borrowing, status: :created, location: @borrowing
    else
      render json: @borrowing.errors, status: :unprocessable_content
    end
  end

  # PATCH/PUT /borrowings/1
  def update
    if @borrowing.update(borrowing_params)
      render json: @borrowing
    else
      render json: @borrowing.errors, status: :unprocessable_content
    end
  end

  # DELETE /borrowings/1
  def destroy
    @borrowing.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_borrowing
      @borrowing = Borrowing.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def borrowing_params
      params.expect(borrowing: [ :book_id, :reader_id, :borrowed_at, :due_on, :returned_at ])
    end
end
