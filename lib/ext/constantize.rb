module NestedDb
  module Constantize
    def constantize(word)
      begin
        super(word)
      rescue NameError => e
        # if this is an instance
        if word =~ NestedDb::Instances.regex
          # try to create
          NestedDb::Instances.find_or_create($1)
        # if it's not an instance
        else
          # re-raise error
          raise
        end
      end
    end
  end
end

ActiveSupport::Inflector.extend(NestedDb::Constantize)