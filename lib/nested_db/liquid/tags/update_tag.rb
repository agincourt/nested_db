module Liquid
  class Update < Tag
    Syntax = /([^\s]+)\sset\s([^\s]+)\s=\s([^\s]+)/
    
    def initialize(tag_name, markup, tokens)
      if markup =~ Syntax
        @instance_name = $1
        @property_name = $2
        @value_name    = $3
      else
        raise SyntaxError.new([
          "Syntax Error in 'update'",
          "Valid syntax: update <variable> set <property> = <variable/value>.",
          "Examples: {% update user set 'username' = params.username %}",
          "          {% update order set 'status' = 'complete' %}"
        ].join("\n"))
      end
      
      super
    end
    
    def render(context)
      # load our instance
      instance = context[@instance_name].try(:instance)
      unless instance && instance.kind_of?(NestedDb::Instance)
        raise SyntaxError.new([
          "Syntax Error in 'update': variable should be an instance of a taxonomy",
          "Valid syntax: update <variable> set <property> = <variable/value>.",
          "Examples: {% update user set 'username' = params.username %}",
          "          {% update order set 'status' = 'complete' %}"
        ].join("\n"))
      end
      # load the property
      property = contextual_value(context, @property_name)
      unless property && instance.taxonomy.physical_properties.map(&:name).include?(property)
        raise SyntaxError.new([
          "Syntax Error in 'update': property should resolve to one of #{instance.taxonomy.physical_properties.map(&:name)}",
          "Valid syntax: update <variable> set <property> = <variable/value>.",
          "Examples: {% update user set 'username' = params.username %}",
          "          {% update order set 'status' = 'complete' %}"
        ].join("\n"))
      end
      # load the value
      if @value_name =~ /^[\d\.]+$/
        value = @value_name.to_f
      else
        value = contextual_value(context, @value_name)
      end
      # update the instance
      instance.update_attributes({ property => value })
      # render nothing
      ''
    end
    
    protected
    def contextual_value(context, value)
      value =~ /^["'](.*)["']$/
      $1 || context[value]
    end
  end
  
  Template.register_tag('update', UpdateTag)
end