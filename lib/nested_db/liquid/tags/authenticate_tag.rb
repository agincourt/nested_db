module Liquid
  class AuthenticateTag < Tag
    Syntax = /as\s([^\s]+)\sagainst\s([^\s]+)\swhere\s([^\s]+)\s==\s([^\s]+)\sand\s([^\s]+)\s==\s([^\s]+)/
    
    def initialize(tag_name, markup, tokens)
      if markup =~ Syntax
        @var_name        = $1
        @collection_name = $2
        @password_field  = $3
        @password_value  = $4
        @condition_field = $5
        @condition_value = $6
      else
        raise SyntaxError.new([
          "Syntax Error in 'authenticate'",
          "Valid syntax: authenticate as <variable> against <taxonomy_reference> where <password_field> == <password_value> and <field> == <value>.",
          "Example: authenticate as current_user against users where password == params.password and username == params.email"
        ].join("\n"))
      end
      
      super
    end
    
    def render(context)
      user = authenticate(context)
      # if the user was set
      if user
        context[@var_name] = NestedDb::Liquid::InstanceDrop.new(user)
        context['session.object']["authentication_token_#{@var_name}"] = user.id
        context['passed?'] = true
        context['failed?'] = false
      else
        context['passed?'] = false
        context['failed?'] = true
      end
      # render nothing
      ''
    end
    
    protected
    def authenticate(context)
      # load the taxonomy
      taxonomy ||= context["taxonomies.#{@collection_name}"].try(:taxonomy)
      # check it was found
      unless taxonomy
        raise SyntaxError.new("Syntax Error in 'authenticate' - Taxonomy `#{@collection_name}` could not be found")
      end
      # find the instance
      instance = taxonomy.instances.where(@condition_field => contextual_value(context, @condition_value)).first
      # return if we couldn't find the instance
      return unless instance
      # try to authenticate the instance
      instance.authenticate(@password_field, contextual_value(context, @password_value))
    end
    
    def contextual_value(context, value)
      value =~ /^["'](.*)["']$/
      $1 || context[value]
    end
  end
  
  Template.register_tag('authenticate', AuthenticateTag)
end