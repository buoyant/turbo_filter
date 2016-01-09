module ActionView
  module Helpers
    module TurboFilterHelper

      def turbo_filters
        render :partial => 'turbo_filters/filters', :layout => false, :locals => {:query => @query}
      end

      def filters_options_for_select(query)
        options_for_select(filters_options(query))
      end

      def filters_options(query)
        options = [[]]
        options += query.available_filters.map do |field, field_options|
          [field_options[:name], field]
        end
      end

      # Helper to render JSON in views
      def raw_json(arg)
        arg.to_json.to_s.gsub('/', '\/').html_safe
      end

      def link_to_function(name, function, html_options={})
        content_tag(:a, name, {:href => '#', :onclick => "#{function}; return false;"}.merge(html_options))
      end

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
end