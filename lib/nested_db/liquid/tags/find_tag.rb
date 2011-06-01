module Liquid
  class FindTag < Block
    Syntax = /(first|all)\s([^\s]+)\sas\s([^\s]+)/
    
    attr_reader :conditions
    
    def initialize(tag_name, markup, tokens)
      if markup =~ Syntax
        @attributes = {}
        @quantity   = $1
        @reference  = $2
        @var_name   = $3
        @conditions = []
      else
        raise SyntaxError.new([
          "Syntax Error in 'find'",
          "Valid syntax: find <first|all> <reference> as <variable_name>",
          "Example:",
          "  {% find all products as products %}",
          "    {% where 'price' > 5 %}",
          "    {% where 'category' == 'fruit' %}",
          "    {% where dynamic_column == dynamic_value %}",
          "    {% order by 'name' %}",
          "    {% limit to 50 %}",
          "  {% endfind %}"
        ].join("\n"))
      end
      
      super
    end
    
    def unknown_tag(tag_name, markup, tokens)
      case tag_name
      when 'where'
        handle_where_tag(markup)
      when 'order'
        handle_order_tag(markup)
      when 'limit'
        handle_limit_tag(markup)
      else
        super
      end
    end
    
    def render(context)
      # load taxonomy
      taxonomy = context["taxonomies.#{@reference}"].try(:taxonomy)
      # check we have it
      raise SyntaxError.new([
        "Syntax Error in 'find'",
        "Taxonomy with reference '#{@reference}' not found!"
      ].join("\n")) unless taxonomy
      # setup base instances
      instances = taxonomy.instances
      # apply scoping
      @conditions.each do |condition|
        instances = case condition[0]
        when 'where'
          column = contextual_value(context, condition[1][:column]).to_sym
          if condition[1][:action].present?
            column = column.send(condition[1][:action])
          end
          instances.where(column => contextual_value(context, condition[1][:value]))
        when 'order'
          instances.order_by(contextual_value(context, condition[1][:column]).to_sym.send(condition[1][:direction]))
        when 'limit'
          instances.limit(contextual_value(context, condition[1][:amount]))
        else
          instances
        end
      end
      # if we only want one
      instances = instances.first if 'first' == @quantity
      # set the context
      context[@var_name] = instances
      ''
    end
    
    private
    def contextual_value(context, value)
      # if it's an int
      return $1.to_i if value =~ /^([\d]+)$/
      # if it's a float
      return $1.to_f if value =~ /^([\d\.]+)$/
      # if it's surrounded by quotes
      value =~ /^["'](.*)["']$/
      # return the raw value, else pull from context
      $1 || context[value]
    end
    
    def handle_where_tag(markup)
      if markup =~ /([^\s]+)\s(\={1,2}|\>|\<|\!\=|in)\s([^\s]+)/
        action = case $2
        when '=', '=='
          nil
        when '>'
          :gt
        when '<'
          :lt
        when '>='
          :gte
        when '<='
          :lte
        when 'in'
          :in
        when '!='
          :ne
        end
        @conditions << ['where', { :column => $1, :action => action, :value => $3 }]
      else
        raise SyntaxError.new([
          "Syntax Error in 'where'",
          "Valid syntax: where <column> <comparison> <value>",
          "Examples:",
          "  {% where price > 5 %}",
          "  {% where category == 'fruit' %}",
          "  {% where title == variable %}"
        ].join("\n"))
      end
    end
    
    def handle_order_tag(markup)
      if markup =~ /by\s([^\s]+)(\s([\"|\']?asc|desc[\"|\']?))?/
        @conditions << ['order', { :column => $1, :direction => $3 || 'desc' }]
      else
        raise SyntaxError.new([
          "Syntax Error in 'order'",
          "Valid syntax: order by <column> <asc|desc>",
          "Examples:",
          "  {% order by 'price' %}",
          "  {% order by 'price' asc %}",
          "  {% order by 'price' desc %}",
          "  {% order by dynamic_column_reference %}"
        ].join("\n"))
      end
    end
    
    def handle_limit_tag(markup)
      if markup =~ /to\s([^\s]+)/
        @conditions << ['limit', { :amount => $1 }]
      else
        raise SyntaxError.new([
          "Syntax Error in 'limit'",
          "Valid syntax: limit to <amount>",
          "Examples:",
          "  {% limit to 50 %}",
          "  {% limit to variable %}"
        ].join("\n"))
      end
    end
  end
  
  Template.register_tag('find', FindTag)
end