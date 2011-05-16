require 'nested_db/models/property'

module NestedDb
  module Models
    module VirtualProperty
      def self.included(base)
        base.send(:include, ::Mongoid::Document)
        base.send(:include, NestedDb::Models::Property)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          extend ClassMethods
          
          # fields
          field :format
          field :casing
          field :only_create, :type => Boolean
          
          # associations
          embedded_in :taxonomy,
            :inverse_of => :virtual_properties,
            :class_name => "NestedDb::Taxonomy"
  
          # validation
          validates_presence_of  :format
          validates_inclusion_of :data_type,
            :in => %w(string decimal integer)
          validates_inclusion_of :casing,
            :in => %w(downcase upcase titleize permalink),
            :allow_blank => true
        end
      end
      
      module ClassMethods
        def data_types
          {
            :string  => String,
            :integer => Integer,
            :decimal => Float
          }
        end
      end
      
      module InstanceMethods
        def field_type
          self.class.data_types[data_type.to_sym] || String
        end
        
        def required?
          false
        end
        
        def field
          ::Mongoid::Field.new(name, :type => self.data_type.classify.constantize)
        end
        
        def value(instance)
          # parse the format
          liquid_template = Liquid::Template.parse(format)
          # render it using the instance
          output = liquid_template.render(taxonomy.physical_properties.inject({}) { |result,pp|
            result.merge({ pp.name => instance.send(pp.name) })
          }.merge({ 'id' => instance.auto_incremented_id }))
          # if we have a casing
          output = case casing
          when 'downcase'
            output.downcase
          when 'upcase'
            output.upcase
          when 'titleize'
            output.titleize
          when 'permalink'
            output.downcase.gsub(/[^\w\-]/, '-').gsub(/\-+/, '-')[0..31]
          else
            output
          end
          # if we have a data type other than string
          output = output.to_f if 'decimal' == data_type
          output = output.to_i if 'integer' == data_type
          # return the output
          output
        end
      end
    end
  end
end