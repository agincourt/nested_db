module Liquid
  class Load < Tag
    Syntax = /^(one|all)\s(.*?)\sas\s(.*?)(\swhere\s(.*?)\s*==\s*(.*?))?(\slimit\sto\s(.*?))?$/
    
    def initialize(tag_name, markup, tokens)          
      if markup =~ Syntax
        @quantity   = $1
        @reference  = $2
        @var_name   = $3
        @column     = $5
        @value      = $6
        @limit      = [[($8 || 100).to_i, 100].min, 0].max
      else
        raise SyntaxError.new("Syntax Error in 'load' - Valid syntax: load <one|all> <reference> as <variable_name> [where <field> == <value>] [limit to <quantity>]")
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
      instances = instances.where(@column => value(context)) unless @column.blank?
      # if we only want one
      if @quantity == 'one'
        # load the first
        instance = instances.find(:first)
        # if we found it, return it
        return NestedDb::InstanceDrop.new(instance, taxonomy_drop(context)) if instance
      # if we want many
      else
        # return an array of instances found
        return instances.limit(@limit).find(:all).map { |instance|
          NestedDb::InstanceDrop.new(instance, taxonomy_drop(context))
        }
      end
      # failing anything, return nil
      nil
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
      context["taxonomies.#{@reference}"]
    end
  end
  
  Template.register_tag('load', Load)
end