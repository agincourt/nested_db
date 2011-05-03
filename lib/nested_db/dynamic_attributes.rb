module NestedDb
  module DynamicAttributes
    def self.included(base)
      base.send(:include, InstanceMethods)
    end
    
    module InstanceMethods
      # allows for typecasting on the dynamic taxonomy fields
      def fields
        self.class.fields.reverse_merge(taxonomy.try(:property_fields) || {})
      end
      
      # intercept read_attribute and check for associations
      def read_attribute(method)
        # if we have no taxonomy, return super
        return super(method) unless taxonomy
        # try to load the property
        property = taxonomy.properties[method.to_s]
        # if we found one, check it's data type (nil defaults to else)
        case property.try(:data_type)
        # if it's a belongs_to associations
        when 'belongs_to'
          # find the singular instance based on the input ID
          property.foreign_taxonomy.instances.find(super(method))
        # if it's a has_many association
        when 'has_many'
          # find all the instances which have this object as their 'belongs_to' value
          property.foreign_taxonomy.instances.where(property.foreign_key => id)
        else
          super(method)
        end
      rescue Mongoid::Errors::DocumentNotFound => e
        Rails.logger.debug "#{e.class.name.to_s} => #{e.message}"
        nil
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