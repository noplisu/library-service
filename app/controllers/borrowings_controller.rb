class BorrowingsController < ApplicationController
  before_action :set_borrowing, only: :update

  def create
    borrowing = Borrowing.new(
      book: Book.find_by(serial_number: borrowing_params[:serial_number]),
      reader: Reader.active.find_by(card_number: borrowing_params[:card_number])
    )

    if borrowing.lend
      render json: borrowing.as_api_json, status: :created
    else
      render json: borrowing.errors, status: :unprocessable_content
    end
  end

  def update
    if @borrowing.returned_at.present?
      @borrowing.errors.add(:returned_at, "is already set")
      render json: @borrowing.errors, status: :unprocessable_content
    elsif @borrowing.update(returned_at: Time.current)
      render json: @borrowing.as_api_json
    else
      render json: @borrowing.errors, status: :unprocessable_content
    end
  end

  private
    def set_borrowing
      @borrowing = Borrowing.find(params[:id])
    end

    def borrowing_params
      params.expect(borrowing: %i[ serial_number card_number ])
    end
end
