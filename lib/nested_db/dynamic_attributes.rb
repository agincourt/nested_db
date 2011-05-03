module NestedDb
  module DynamicAttributes
    def self.included(base)
      base.send(:include, InstanceMethods)
    end
    
    module InstanceMethods
      # allows for typecasting on the dynamic taxonomy fields
      def fields
        super.reverse_merge(taxonomy.try(:property_fields) || {})
      end
      
      # allows for readers when the attribute hasn't been
      # physically defined yet
      def method_missing(method, *args)
        if taxonomy && taxonomy.has_property?(method)
          read_attribute(method)
        else
          super(method, args)
        end
      end
      
      private
      # overwrite process attribute to allow for non-typical file types
      def process_attribute(name, value)
        if taxonomy && taxonomy.has_property?(method) && 'file' == taxonomy.properties[method].data_type
          write_file_attribute(name, value)
        else
          super(name, value)
        end
      end
      
      # stores files temporarily for processing
      def write_file_attribute(name, value)
        # store the file
        @pending_files ||= {}
        @pending_files.merge!(name => value)
        # write the value
        write_attribute(name, File.basename(value.path))
      end
    end
  end
end