module Liquid
  class CreateTag < Tag
    Syntax = /new\s([^\s]+)\sin\s([^\s]+)\susing\s([^\s]+)/
    
    def initialize(tag_name, markup, tokens)
      if markup =~ Syntax
        @var_name        = $1
        @collection_name = $2
        @parameters      = $3
      else
        raise SyntaxError.new([
          "Syntax Error in 'create'",
          "Valid syntax: create new <variable> in <taxonomy_reference> using <variable>.",
          "Example: {% create new user in users using params.user %}",
          "         {% if user.persisted? %}<p>User saved!</p>{% endif %}",
          "         {% if user.new_record? %}",
          "           <p>User not saved!</p>",
          "           <ul>{% for error in user.errors %}<li>{{ error.field }} {{ error.message }}</li>{% endfor %}</ul>",
          "         {% endif %}",
        ].join("\n"))
      end
      
      super
    end
    
    def render(context)
      instance = taxonomy(context).instances.build
      instance.write_attributes(context[@parameters] || {})
      instance.save
      # store the instance
      context[@var_name] = NestedDb::Liquid::InstanceDrop.new(instance)
      # render nothing
      ''
    end
    
    protected
    def taxonomy(context)
      # load the taxonomy
      taxonomy ||= context["taxonomies.#{@collection_name}"].try(:taxonomy)
      # check it was found
      unless taxonomy
        raise SyntaxError.new("Syntax Error in 'create' - Taxonomy `#{@collection_name}` could not be found")
      end
      # return taxonomy
      taxonomy
    end
  end
  
  Template.register_tag('create', CreateTag)
end