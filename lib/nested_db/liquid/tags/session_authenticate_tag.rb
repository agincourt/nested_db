module Liquid
  class SessionAuthenticateTag < Block
    Syntax = /([^\s]+)/
    
    def initialize(tag_name, markup, tokens)
      if markup =~ Syntax
        @var_name = $1
      else
        raise SyntaxError.new([
          "Syntax Error in 'session_authenticate'",
          "Valid syntax: sessionauthenticate <variable>.",
          "Example: {% sessionauthenticate current_user %}<p>Session auth failed!</p>{% endsessionauthenticate %}"
        ].join("\n"))
      end
      
      super
    end
    
    def render(context)
      if context['session.object']["authentication_token_#{@var_name}"]
        user = NestedDb::Instance.where(:_id => context['session.object']["authentication_token_#{@var_name}"]).first
        context[@var_name] = NestedDb::InstanceDrop.new(user) if user
        context['passed?'] = !!user
        context['failed?'] = !user
      end
      # render nothing if we found a user, otherwise parse the block
      user ? '' : super(context)
    end
  end
  
  Template.register_tag('sessionauthenticate', SessionAuthenticateTag)
end