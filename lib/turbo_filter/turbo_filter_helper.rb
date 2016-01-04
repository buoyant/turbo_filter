module ActionView
  module Helpers
    module TurboFilterHelper

      def turbo_filters_for filters_for_class=nil
        tfq = TurboFilterQuery.new(filters_for_class)
        render :partial => 'turbo_filters/filters', :layout => false, :locals => {:query => tfq}
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

      def query_filters_hidden_tags(query)
        tags = ''.html_safe
        query.filters.each do |field, options|
          tags << hidden_field_tag("f[]", field, :id => nil)
          tags << hidden_field_tag("op[#{field}]", options[:operator], :id => nil)
          options[:values].each do |value|
            tags << hidden_field_tag("v[#{field}][]", value, :id => nil)
          end
        end
        tags
      end

      def query_columns_hidden_tags(query)
        tags = ''.html_safe
        query.columns.each do |column|
          tags << hidden_field_tag("c[]", column.name, :id => nil)
        end
        tags
      end

      def query_hidden_tags(query)
        query_filters_hidden_tags(query) + query_columns_hidden_tags(query)
      end

      def available_block_columns_tags(query)
        tags = ''.html_safe
        query.available_block_columns.each do |column|
          tags << content_tag('label', check_box_tag('c[]', column.name.to_s, query.has_column?(column), :id => nil) + " #{column.caption}", :class => 'inline')
        end
        tags
      end

      # Helper to render JSON in views
      def raw_json(arg)
        arg.to_json.to_s.gsub('/', '\/').html_safe
      end

    end
  end
end