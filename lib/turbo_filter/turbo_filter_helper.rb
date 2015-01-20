module ActionView
  module Helpers
  	module TurboFilterHelper

  		def turbo_filters_for s  			
  			tfq = TurboFilterQuery.new
	      tfq.add_available_filter "status_id",
	      :type => :list_optional, :values => MerchantStatus.sorted.collect{|s| [s.name, s.id.to_s] }, :name => 'Status'

	      tfq.add_available_filter "tracker_id",
	        :type => :list, :values => Tracker.all.collect{ |s| [s.name, s.id.to_s] }

	      tfq.add_available_filter "priority_id",
	        :type => :list, :values => MerchantPriority.all.collect{|s| [s.name, s.id.to_s] }

  			render :partial => 'turbo_filters/filters', :layout => false, :locals => {:query => tfq}
  		end

  		def include_calendar_headers_tags
		    unless @calendar_headers_tags_included
		      tags = javascript_include_tag("datepicker")
		      @calendar_headers_tags_included = true
		      content_for :header_tags do
		        start_of_week = Setting.start_of_week
		        start_of_week = l(:general_first_day_of_week, :default => '1') if start_of_week.blank?
		        # TurboFilter uses 1..7 (monday..sunday) in settings and locales
		        # JQuery uses 0..6 (sunday..saturday), 7 needs to be changed to 0
		        start_of_week = start_of_week.to_i % 7
		        tags << javascript_tag(
		                   "var datepickerOptions={dateFormat: 'yy-mm-dd', firstDay: #{start_of_week}, " +
		                     "showOn: 'button', buttonImageOnly: true, buttonImage: '" +
		                     path_to_image('/images/calendar.png') +
		                     "', showButtonPanel: true, showWeek: true, showOtherMonths: true, " +
		                     "selectOtherMonths: true, changeMonth: true, changeYear: true, " +
		                     "beforeShow: beforeShowDatePicker};")
		        jquery_locale = l('jquery.locale', :default => current_language.to_s)
		        unless jquery_locale == 'en'
		          tags << javascript_include_tag("i18n/datepicker-#{jquery_locale}.js")
		        end
		        tags
		      end
		    end
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

  	end
  end
end