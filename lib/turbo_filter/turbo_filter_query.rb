module TurboFilter
  class TurboFilterQuery

      class_attribute :filters
      class_attribute :operators
      self.operators = {
        "="   => :label_equals,
        "!"   => :label_not_equals,
        "!*"  => :label_none,
        "*"   => :label_any,
        ">="  => :label_greater_or_equal,
        "<="  => :label_less_or_equal,
        "><"  => :label_between,
        "<t+" => :label_in_less_than,
        ">t+" => :label_in_more_than,
        "><t+"=> :label_in_the_next_days,
        "t+"  => :label_in,
        "t"   => :label_today,
        "ld"  => :label_yesterday,
        "w"   => :label_this_week,
        "lw"  => :label_last_week,
        "l2w" => [:label_last_n_weeks, {:count => 2}],
        "m"   => :label_this_month,
        "lm"  => :label_last_month,
        "y"   => :label_this_year,
        ">t-" => :label_less_than_ago,
        "<t-" => :label_more_than_ago,
        "><t-"=> :label_in_the_past_days,
        "t-"  => :label_ago,
        "~"   => :label_contains,
        "!~"  => :label_not_contains
      }

      class_attribute :operators_by_filter_type
      self.operators_by_filter_type = {
        :list => [ "=", "!" ],
        :list_optional => [ "=", "!", "!*", "*" ],
        :date => [ "=", ">=", "<=", "><", "<t+", ">t+", "><t+", "t+", "t", "ld", "w", "lw", "l2w", "m", "lm", "y", ">t-", "<t-", "><t-", "t-", "!*", "*" ],
        :date_past => [ "=", ">=", "<=", "><", ">t-", "<t-", "><t-", "t-", "t", "ld", "w", "lw", "l2w", "m", "lm", "y", "!*", "*" ],
        :string => [ "=", "~", "!", "!~", "!*", "*" ],
        :text => [  "~", "!~", "!*", "*" ],
        :integer => [ "=", ">=", "<=", "><", "!*", "*" ],
        :float => [ "=", ">=", "<=", "><", "!*", "*" ]
      }

    # Returns a hash of localized labels for all filter operators
    def self.operators_labels
      operators.inject({}) {|h, operator| h[operator.first] = I18n.t(*operator.last); h}
    end

    def initialize(filters_for_class=nil,filters={})
      @filters_for_class = filters_for_class
      self.filters = filters
    end

    # Adds available filters
    def initialize_available_filters
      if @filters_for_class.is_a?(Class) && (@filters_for_class.superclass == ActiveRecord::Base)
        associations = @filters_for_class.reflect_on_all_associations(:belongs_to)
        association_foreign_keys = associations.map(&:foreign_key)
        @filters_for_class.columns.each do |col|
          case col.type
          when :string
            add_available_filter col.name, :type => :text
          when :date
            add_available_filter col.name, :type => :date
          when :datetime
            add_available_filter col.name, :type => :date_past
          when :float
            add_available_filter col.name, :type => :float
          when :integer
            if association_foreign_keys.include?(col.name)
              association_class = associations.select { |a| a.foreign_key == col.name }.first.class_name.constantize
              association_values = association_class.all.collect{|s| [s.to_s, s.id.to_s] }
              add_available_filter col.name, :type => :list, :values => association_values
            else
              add_available_filter col.name, :type => :integer
            end
          when :boolean
            add_available_filter col.name, :type => :list, :values => [["Yes","1"],["No", "0"]]
          end # case
        end # do
      end
    end
    protected :initialize_available_filters

    # Adds an available filter
    def add_available_filter(field, options)
      @available_filters ||= ActiveSupport::OrderedHash.new
      @available_filters[field] = options
      @available_filters
    end

    # Removes an available filter
    def delete_available_filter(field)
      if @available_filters
        @available_filters.delete(field)
      end
    end

    # Return a hash of available filters
    def available_filters
      unless @available_filters
        initialize_available_filters
        @available_filters.to_a.each do |field, options|
          options[:name] ||= I18n.t("field_#{field}".gsub(/_id$/, ''))
        end
      end
      @available_filters
    end

    def add_filter(field, operator, values=nil)
      # values must be an array
      return unless values.nil? || values.is_a?(Array)
      # check if field is defined as an available filter
      if available_filters.has_key? field
        filter_options = available_filters[field]
        filters[field] = {:operator => operator, :values => (values || [''])}
      end
    end

    def add_short_filter(field, expression)
      return unless expression && available_filters.has_key?(field)
      field_type = available_filters[field][:type]
      operators_by_filter_type[field_type].sort.reverse.detect do |operator|
        next unless expression =~ /^#{Regexp.escape(operator)}(.*)$/
        values = $1
        add_filter field, operator, values.present? ? values.split('|') : ['']
      end || add_filter(field, '=', expression.split('|'))
    end

    # Add multiple filters using +add_filter+
    def add_filters(fields, operators, values)
      if fields.is_a?(Array) && operators.is_a?(Hash) && (values.nil? || values.is_a?(Hash))
        fields.each do |field|
          add_filter(field, operators[field], values && values[field])
        end
      end
    end

    def has_filter?(field)
      filters and filters[field]
    end

    def type_for(field)
      available_filters[field][:type] if available_filters.has_key?(field)
    end

    def operator_for(field)
      has_filter?(field) ? filters[field][:operator] : nil
    end

    def values_for(field)
      has_filter?(field) ? filters[field][:values] : nil
    end

    def value_for(field, index=0)
      (values_for(field) || [])[index]
    end

    def label_for(field)
      label = available_filters[field][:name] if available_filters.has_key?(field)
      label ||= l("field_#{field.to_s.gsub(/_id$/, '')}", :default => field)
    end

    # Returns a representation of the available filters for JSON serialization
    def available_filters_as_json
      json = {}
      available_filters.to_a.each do |field, options|
        json[field] = options.slice(:type, :name, :values).stringify_keys
      end
      json
    end

    def statement
      # filters clauses
      filters_clauses = []
      filters.each_key do |field|
        v = values_for(field).clone
        next unless v and !v.empty?
        operator = operator_for(field)

        filters_clauses << '(' + sql_for_field(field, operator, v, @filters_for_class.table_name, field) + ')'
      end if filters

      filters_clauses.reject!(&:blank?)

      filters_clauses.any? ? filters_clauses.join(' AND ') : nil
    end


    # Helper method to generate the WHERE sql for a +field+, +operator+ and a +value+
    def sql_for_field(field, operator, value, db_table, db_field)
      sql = ''
      case operator
      when "="
        if value.any?
          case type_for(field)
          when :date, :date_past
            sql = date_clause(db_table, db_field, parse_date(value.first), parse_date(value.first))
          when :integer
            sql = "#{db_table}.#{db_field} = #{value.first.to_i}"
          when :float
            sql = "#{db_table}.#{db_field} BETWEEN #{value.first.to_f - 1e-5} AND #{value.first.to_f + 1e-5}"
          else
            sql = "#{db_table}.#{db_field} IN (" + value.collect{|val| "'#{@filters_for_class.connection.quote_string(val)}'"}.join(",") + ")"
          end
        else
          # IN an empty set
          sql = "1=0"
        end
      when "!"
        if value.any?
          sql = "(#{db_table}.#{db_field} IS NULL OR #{db_table}.#{db_field} NOT IN (" + value.collect{|val| "'#{@filters_for_class.connection.quote_string(val)}'"}.join(",") + "))"
        else
          # NOT IN an empty set
          sql = "1=1"
        end
      when "!*"
        sql = "#{db_table}.#{db_field} IS NULL"
      when "*"
        sql = "#{db_table}.#{db_field} IS NOT NULL"
      when ">="
        if [:date, :date_past].include?(type_for(field))
          sql = date_clause(db_table, db_field, parse_date(value.first), nil)
        else
          sql = "#{db_table}.#{db_field} >= #{value.first.to_f}"
        end
      when "<="
        if [:date, :date_past].include?(type_for(field))
          sql = date_clause(db_table, db_field, nil, parse_date(value.first))
        else
          sql = "#{db_table}.#{db_field} <= #{value.first.to_f}"
        end
      when "><"
        if [:date, :date_past].include?(type_for(field))
          sql = date_clause(db_table, db_field, parse_date(value[0]), parse_date(value[1]))
        else
          sql = "#{db_table}.#{db_field} BETWEEN #{value[0].to_f} AND #{value[1].to_f}"
        end
      when "><t-"
        # between today - n days and today
        sql = relative_date_clause(db_table, db_field, - value.first.to_i, 0)
      when ">t-"
        # >= today - n days
        sql = relative_date_clause(db_table, db_field, - value.first.to_i, nil)
      when "<t-"
        # <= today - n days
        sql = relative_date_clause(db_table, db_field, nil, - value.first.to_i)
      when "t-"
        # = n days in past
        sql = relative_date_clause(db_table, db_field, - value.first.to_i, - value.first.to_i)
      when "><t+"
        # between today and today + n days
        sql = relative_date_clause(db_table, db_field, 0, value.first.to_i)
      when ">t+"
        # >= today + n days
        sql = relative_date_clause(db_table, db_field, value.first.to_i, nil)
      when "<t+"
        # <= today + n days
        sql = relative_date_clause(db_table, db_field, nil, value.first.to_i)
      when "t+"
        # = today + n days
        sql = relative_date_clause(db_table, db_field, value.first.to_i, value.first.to_i)
      when "t"
        # = today
        sql = relative_date_clause(db_table, db_field, 0, 0)
      when "ld"
        # = yesterday
        sql = relative_date_clause(db_table, db_field, -1, -1)
      when "w"
        # = this week
        first_day_of_week = l(:general_first_day_of_week).to_i
        day_of_week = Date.today.cwday
        days_ago = (day_of_week >= first_day_of_week ? day_of_week - first_day_of_week : day_of_week + 7 - first_day_of_week)
        sql = relative_date_clause(db_table, db_field, - days_ago, - days_ago + 6)
      when "lw"
        # = last week
        first_day_of_week = l(:general_first_day_of_week).to_i
        day_of_week = Date.today.cwday
        days_ago = (day_of_week >= first_day_of_week ? day_of_week - first_day_of_week : day_of_week + 7 - first_day_of_week)
        sql = relative_date_clause(db_table, db_field, - days_ago - 7, - days_ago - 1)
      when "l2w"
        # = last 2 weeks
        first_day_of_week = l(:general_first_day_of_week).to_i
        day_of_week = Date.today.cwday
        days_ago = (day_of_week >= first_day_of_week ? day_of_week - first_day_of_week : day_of_week + 7 - first_day_of_week)
        sql = relative_date_clause(db_table, db_field, - days_ago - 14, - days_ago - 1)
      when "m"
        # = this month
        date = Date.today
        sql = date_clause(db_table, db_field, date.beginning_of_month, date.end_of_month)
      when "lm"
        # = last month
        date = Date.today.prev_month
        sql = date_clause(db_table, db_field, date.beginning_of_month, date.end_of_month)
      when "y"
        # = this year
        date = Date.today
        sql = date_clause(db_table, db_field, date.beginning_of_year, date.end_of_year)
      when "~"
        sql = "LOWER(#{db_table}.#{db_field}) LIKE '%#{@filters_for_class.connection.quote_string(value.first.to_s.downcase)}%'"
      when "!~"
        sql = "LOWER(#{db_table}.#{db_field}) NOT LIKE '%#{@filters_for_class.connection.quote_string(value.first.to_s.downcase)}%'"
      else
        raise "Unknown query operator #{operator}"
      end

      return sql
    end

    # Returns a SQL clause for a date or datetime field.
    def date_clause(table, field, from, to)
      s = []
      if from
        if from.is_a?(Date)
          from = Time.local(from.year, from.month, from.day).yesterday.end_of_day
        else
          from = from - 1 # second
        end
        if self.class.default_timezone == :utc
          from = from.utc
        end
        s << ("#{table}.#{field} > '%s'" % [@filters_for_class.connection.quoted_date(from)])
      end
      if to
        if to.is_a?(Date)
          to = Time.local(to.year, to.month, to.day).end_of_day
        end
        if self.class.default_timezone == :utc
          to = to.utc
        end
        s << ("#{table}.#{field} <= '%s'" % [@filters_for_class.connection.quoted_date(to)])
      end
      s.join(' AND ')
    end

    # Returns a SQL clause for a date or datetime field using relative dates.
    def relative_date_clause(table, field, days_from, days_to)
      date_clause(table, field, (days_from ? Date.today + days_from : nil), (days_to ? Date.today + days_to : nil))
    end

    # Returns a Date or Time from the given filter value
    def parse_date(arg)
      if arg.to_s =~ /\A\d{4}-\d{2}-\d{2}T/
        Time.parse(arg) rescue nil
      else
        Date.parse(arg) rescue nil
      end
    end

  end
end