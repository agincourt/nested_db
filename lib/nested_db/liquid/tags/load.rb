module Liquid
  class Load < Tag
    Syntax = /^(one|all)\s(.*?)\sas\s(.*?)\swhere\s(.*?)\s*==\s*(.*?)$/
    
    def initialize(tag_name, markup, tokens)          
      if markup =~ Syntax
        @quantity   = $1
        @reference  = $2
        @var_name = $3
        @column     = $4
        @value      = $5
      else
        raise SyntaxError.new("Syntax Error in 'load' - Valid syntax: load [one|all] [taxonomy.reference] as [variable] where [field] == [value]")
      end
      
      super
    end
    
    def render(context)
      context.scopes.last[@var_name] = var_value(context)
      ''
    end
    
    private
    def var_value(context)
      if @quantity == 'one'
        instance = taxonomy(context).instances.where(@column => value(context)).find(:first)
        return NestedDb::InstanceDrop.new(instance, taxonomy_drop(context)) if instance
      else
        return taxonomy(context).instances.where(@column => value(context)).limit(100).map { |instance|
          NestedDb::InstanceDrop.new(instance, taxonomy_drop(context))
        }
      end
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