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
      context.scopes.last[@var_name] = var_value
      ''
    end
    
    private
    def var_value
      if @quantity == 'one'
        instance = taxonomy.instances.where(@column => context_value).find(:first)
        InstanceDrop.new(instance, taxonomy_drop) if instance
      else
        taxonomy.instances.where(@column => context_value).limit(100).map { |instance|
          InstanceDrop.new(instance, taxonomy_drop)
        }
      end
    end
    
    # load the value from the context
    def context_value
      context.scopes.last[@value]
    end
    
    # load the taxonomy from it's drop
    def taxonomy
      taxonomy_drop.taxonomy
    end
    
    # load the taxonomy drop based on the reference
    def taxonomy_drop
      context.scopes.last["taxonomies.#{@reference}"]
    end
  end
  
  Template.register_tag('load', Load)
end