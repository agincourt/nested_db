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
        raise SyntaxError.new("Syntax Error in 'load' - Valid syntax: load <one|all> <reference> as <variable_name> [where: '<field> < ==|>|< > <value>'] [limit: <quantity>]")
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
      instances = instances.where(conditions(context)) if conditions?
      # if we only want one
      if @quantity == 'one'
        Rails.logger.debug "Finding first #{@reference} instance, using conditions: #{conditions(context).inspect}"
        # load the first
        instance = instances.first
        # if we found it, return it
        return NestedDb::InstanceDrop.new(instance, taxonomy_drop(context)) if instance
        # otherwise return nil
        nil
      # if we want many
      else
        # return an array of instances found
        return instances.limit(@limit).map { |instance|
          NestedDb::InstanceDrop.new(instance, taxonomy_drop(context))
        }
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
    
    def conditions(context)
      if @attributes['where'] =~ /^['|"](.*)\s(==|>|<)\s(.*)['|"]$/i
        case $2
        when '=='
          { $1.to_sym => context[$3] }
        when '>'
          { $1.to_sym.gt => context[$3] }
        when '<'
          { $1.to_sym.lt => context[$3] }
        end
      else
        {}
      end
    end
  end
  
  Template.register_tag('load', Load)
end