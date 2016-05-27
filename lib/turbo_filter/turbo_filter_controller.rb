module TurboFilter
  module TurboFilterController

    # Retrieve query from session or build a new query
    def retrieve_turbo_filter_query(filters_for_class)
      session_name = (filters_for_class.to_s.downcase + '_query').to_sym
      if params[:set_filter] || session[session_name].nil?
        # Give it a name, required to be valid
        @turbo_filter_query = TurboFilter::TurboFilterQuery.new(filters_for_class)
        build_turbo_filter_query_from_params(session_name)
        session[session_name] = {:filters => @turbo_filter_query.filters}
      else
        # retrieve from session
        @turbo_filter_query ||= TurboFilter::TurboFilterQuery.new(filters_for_class, session[session_name][:filters])
        build_turbo_filter_query_from_params(session_name)
      end
    end

    # def retrieve_turbo_filter_query_from_session
    #   if session[:query]
    #     @turbo_filter_query = TurboFilter::TurboFilterQuery.new(filters_for_class, session[:query][:filters])
    #   end
    # end

    def build_turbo_filter_query_from_params(session_name)
      if params[:f]
        filters = if session[session_name]
                    session[session_name][:filters] = session[session_name][:filters].select { |k,v| params[:f].reject(&:blank?).include?(k) }
                  else
                    {}
                  end
        @turbo_filter_query.filters = filters
        @turbo_filter_query.add_filters(params[:f], params[:operators] || params[:op], params[:values] || params[:v])
      end
    end
  end
end