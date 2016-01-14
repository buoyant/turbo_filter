module TurboFilter
  module TurboFilterController

    # Retrieve query from session or build a new query
    def retrieve_turbo_filter_query(filters_for_class)
      if params[:set_filter] || session[:query].nil?
        # Give it a name, required to be valid
        @turbo_filter_query = TurboFilter::TurboFilterQuery.new(filters_for_class)
        build_turbo_filter_query_from_params
        session[:query] = {:filters => @turbo_filter_query.filters}
      else
        # retrieve from session
        @turbo_filter_query ||= TurboFilter::TurboFilterQuery.new(filters_for_class, session[:query][:filters])
        build_turbo_filter_query_from_params
      end
    end

    def retrieve_turbo_filter_query_from_session
      if session[:query]
        @turbo_filter_query = TurboFilter::TurboFilterQuery.new(filters_for_class, session[:query][:filters])
      end
    end

    def build_turbo_filter_query_from_params
      if params[:f]
        filters = if session[:query]
                    session[:query][:filters] = session[:query][:filters].select { |k,v| params[:f].reject(&:blank?).include?(k) }
                  else
                    {}
                  end
        @turbo_filter_query.filters = filters
        @turbo_filter_query.add_filters(params[:f], params[:operators] || params[:op], params[:values] || params[:v])
      end
    end
  end
end