module Liquid
  class DeauthenticateTag < Tag
    Syntax = /([^\s]+)/
    
    def initialize(tag_name, markup, tokens)
      if markup =~ Syntax
        @var_name = $1
      else
        raise SyntaxError.new([
          "Syntax Error in 'deauthenticate'",
          "Valid syntax: deauthenticate <variable>.",
          "Example: deauthenticate current_user"
        ].join("\n"))
      end
      
      super
    end
    
    def render(context)
      context[@var_name] = nil
      context['session.object']["authentication_token_#{@var_name}"] = nil
      # render nothing
      ''
    end
  end
  
  Template.register_tag('deauthenticate', DeauthenticateTag)
end