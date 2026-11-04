class ApplicationController < ActionController::API
  include Pagy::Method

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Not found" }, status: :not_found
  end
  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: e.message }, status: :bad_request
  end
  rescue_from ActiveRecord::RecordNotUnique do
    render json: { error: "Record already exists or book is already borrowed" }, status: :conflict
  end

  private
    def paginate(scope)
      pagy, records = pagy(:offset, scope)
      meta = pagy.data_hash(data_keys: %i[page limit count pages])

      [
        records,
        {
          page: meta[:page],
          per_page: meta[:limit],
          total_count: meta[:count],
          total_pages: meta[:pages]
        }
      ]
    end
end
