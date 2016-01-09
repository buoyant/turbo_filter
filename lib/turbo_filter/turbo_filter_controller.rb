module TurboFilter
  module TurboFilterController

    # Retrieve query from session or build a new query
    def retrieve_query(filters_for_class)
      if params[:set_filter] || session[:query].nil?
        # Give it a name, required to be valid
        @query = TurboFilter::TurboFilterQuery.new(filters_for_class)
        build_query_from_params
        session[:query] = {:filters => @query.filters}
      else
        # retrieve from session
        @query ||= TurboFilter::TurboFilterQuery.new(filters_for_class, session[:query][:filters])
        build_query_from_params
      end
    end

    def retrieve_query_from_session
      if session[:query]
        @query = TurboFilter::TurboFilterQuery.new(filters_for_class, session[:query][:filters])
      end
    end

    def build_query_from_params
      if params[:fields] || params[:f]
        @query.filters = session[:query] ? session[:query][:filters] : {}
        @query.add_filters(params[:fields] || params[:f], params[:operators] || params[:op], params[:values] || params[:v])
      end
    end
  end
end