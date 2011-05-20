module Liquid
  class Load < Tag
    Syntax = /(one|all)\s([^\s]+)\sas\s([^\s]+)/
    
    def initialize(tag_name, markup, tokens)
      if markup =~ Syntax
        @attributes = {}
        @quantity   = $1
        @reference  = $2
        @var_name   = $3
        markup.scan(TagAttributes) do |key, value|
          @attributes[key] = value
        end
        @limit = [[(@attributes['limit'] || 100).to_i, 100].min, 0].max
      else
        raise SyntaxError.new("Syntax Error in 'load' - Valid syntax: load <one|all> <reference> as <variable_name> [where: '<field> < in|==|!=|>|< > <value>'] [limit: <quantity>]")
      end
      
      super
    end
    
    def render(context)
      context[@var_name] = var_value(context)
      ''
    end
    
    private
    def var_value(context)
      # load the taxonomy instances relation
      instances = taxonomy(context).instances
      # if we have conditions, enforce them
      instances = apply_conditions(instances, context) if conditions?
      # if we only want one
      if @quantity == 'one'
        # return the first only
        instances.first
      # if we want many
      else
        # return an array of instances found
        instances.limit(@limit)
      end
    end
    
    # load the value from the context
    def value(context)
      context[@value]
    end
    
    # load the taxonomy from it's drop
    def taxonomy(context)
      taxonomy_drop(context).taxonomy
    end
    
    # load the taxonomy drop based on the reference
    def taxonomy_drop(context)
      drop = context["taxonomies.#{@reference}"]
      unless drop
        raise StandardError, "No taxonomy found with reference: #{@reference}"
      end
      drop
    end
    
    def conditions?
      @attributes.has_key?('where')
    end
    
    def apply_conditions(scope, context)
      if @attributes['where'] =~ /^['|"](.*)\s(in|==|!=|>|<)\s(.*)['|"]$/i
        field, operand, value = $1, $2, $3
        
        # process the value
        case value.strip
        # when it's the keywords blank or nil
        when 'blank', 'nil'
          # ensure the operand is == or !=
          unless ['!=', '=='].include?(operand)
            raise SyntaxError.new("Syntax Error in 'load' where condition - Valid syntax: you can't use blank with any operand other than == or !=")
          end
          # update it to an exists/not_exists
          operand = '!=' == operand ? 'exists' : 'not_exists'
        # if it's surrounded with quotes - we want the raw value
        when /^['|"](.*)['|"]$/
          value = $1
        # otherwise pull it as a variable from the context
        else
          value = context[value]
        end
        
        # look up the operand and process
        case operand
        when '=='
          return scope.where({ field.to_sym => value })
        when 'in'
          return scope.where({ field.to_sym.in => value })
        when '>'
          return scope.where({ field.to_sym.gt => value })
        when '<'
          return scope.where({ field.to_sym.lt => value })
        when 'exists'
          return scope.where({ field.to_sym.exists => true }).where({ field.to_sym.ne => '' }).where({ field.to_sym.ne => 0 })
        when 'not_exists'
          return scope.any_of({ field.to_sym.exists => false }, { field.to_sym => '' }, { field.to_sym => 0 })
        end
      end
      # default to empty array
      scope
    end
  end
  
  Template.register_tag('load', Load)
end