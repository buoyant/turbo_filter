module TurboFilter
  module TurboFilterHelper

    def turbo_filters
      render :partial => 'turbo_filters/filters', :layout => false, :locals => {:turbo_filter_query => @turbo_filter_query}
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
  end
end