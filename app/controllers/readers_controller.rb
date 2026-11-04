class ReadersController < ApplicationController
  before_action :set_reader, only: %i[ show update destroy ]

  def index
    readers, meta = paginate(Reader.active.order(:card_number))

    render json: {
      readers: readers.map(&:as_api_json),
      **meta
    }
  end

  def show
    render json: @reader.as_api_json
  end

  def create
    reader = Reader.new(reader_params)

    if reader.save
      render json: reader.as_api_json, status: :created
    else
      render json: reader.errors, status: :unprocessable_content
    end
  end

  def update
    if @reader.update(reader_params)
      render json: @reader.as_api_json
    else
      render json: @reader.errors, status: :unprocessable_content
    end
  end

  def destroy
    if @reader.deactivate
      head :no_content
    else
      render json: @reader.errors, status: :unprocessable_content
    end
  end

  private
    def set_reader
      @reader = Reader.active.find_by!(card_number: params[:card_number])
    end

    def reader_params
      params.expect(reader: %i[ card_number full_name email ])
    end
end
