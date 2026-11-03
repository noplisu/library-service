class ReadersController < ApplicationController
  before_action :set_reader, only: %i[ show update destroy ]

  def index
    readers, meta = paginate(Reader.active.order(:card_number))

    render json: {
      readers: readers.map { |reader| reader_json(reader) },
      **meta
    }
  end

  def show
    render json: reader_json(@reader)
  end

  def create
    reader = Reader.new(reader_params)

    if reader.save
      render json: reader_json(reader), status: :created
    else
      render json: reader.errors, status: :unprocessable_content
    end
  end

  def update
    if @reader.update(reader_params)
      render json: reader_json(@reader)
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

    def reader_json(reader)
      {
        card_number: reader.card_number,
        full_name: reader.full_name,
        email: reader.email
      }
    end
end
