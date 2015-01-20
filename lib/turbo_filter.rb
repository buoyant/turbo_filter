require 'turbo_filter/engine'
require "turbo_filter/version"
require "turbo_filter/turbo_filter_query"
require 'turbo_filter/turbo_filter_helper'

ActiveSupport.on_load(:action_view) do
  ::ActionView::Base.send :include, ActionView::Helpers::TurboFilterHelper
end

ActionController::Base.prepend_view_path File.dirname(__FILE__) + "/../app/views"

module TurboFilter
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    # Options:
    # * :columns - a column or an array of columns to search
    def acts_as_turbo_filter(options = {})
      return if self.included_modules.include?(TurboFilter::InstanceMethods)

      cattr_accessor :filterable_options
      self.filterable_options = options

      if filterable_options[:columns].nil?
        raise 'No filterable column defined.'
      elsif !filterable_options[:columns].is_a?(Array)
        filterable_options[:columns] = [] << filterable_options[:columns]
      end

      send :include, TurboFilter::InstanceMethods
    end
  end

  module InstanceMethods
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # Searches the model for the given tokens
      # projects argument can be either nil (will search all projects), a project or an array of projects
      # Returns the results and the results count
      def turbo_filter(options={})

        find_options = {:include => filterable_options[:include]}

        limit_options = {}
        limit_options[:limit] = options[:limit] if options[:limit]
        if options[:offset]
          limit_options[:conditions] = "('#{connection.quoted_date(options[:offset])}')"
        end

        columns = filterable_options[:columns]

        # Filter according to these columns.
        token_clauses = columns.collect {|column| "(LOWER(#{column}) LIKE ?)"}

        sql = (['(' + token_clauses.join(' OR ') + ')'] * tokens.size).join(options[:all_words] ? ' AND ' : ' OR ')

        find_options[:conditions] = [sql, * (tokens.collect {|w| "%#{w.downcase}%"} * token_clauses.size).sort]

        scope = self
        results = []
        results_count = 0

        scope = scope.scoped(find_options)
        results = scope.find(:all, limit_options)

        results
      end
    end
  end
end

ActiveRecord::Base.send(:include, TurboFilter)