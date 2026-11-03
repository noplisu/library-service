class ApplicationController < ActionController::API
  include Pagy::Method

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
