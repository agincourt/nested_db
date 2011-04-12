module Liquid
  class Define < Tag
    Syntax = /(#{VariableSignature}+)\s*=\s*([^=]+)/
    
    def initialize(tag_name, markup, tokens)          
      if markup =~ Syntax
        @to = $1
        @from = $2
      else
        raise SyntaxError.new("Syntax Error in 'define' - Valid syntax: define [var] = [source]")
      end
      
      super
    end
    
    def render(context)
      context.scopes.last[@to] = context.scopes.last[@from]
      ''
    end
  end
  
  Template.register_tag('define', Define)
end