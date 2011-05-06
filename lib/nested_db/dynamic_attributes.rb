module NestedDb
  module DynamicAttributes
    def self.included(base)
      base.extend ClassMethods
      base.send(:include, InstanceMethods)
      # setup our callbacks
      base.class_eval do
        
        attr_accessor :extended_from_taxonomy
        
        after_build do
          extend_based_on_taxonomy
        end
        
        after_initialize do
          extend_based_on_taxonomy if taxonomy
        end
        
      end
    end
    
    module InstanceMethods
      def metaclass
        # memoize
        return @metaclass if defined?(@metaclass)
        # load the meta class
        @metaclass = class << self; self; end
        # define a name on it
        @metaclass.class_eval %Q{
          def self.name
            superclass.name
          end
        }
        # return it
        @metaclass
      end
      
      def uploaders
        metaclass.uploaders
      end
      
      def uploader_options
        metaclass.uploader_options
      end
      
      protected
      # dynamically adds fields for each of the taxonomy's properties
      def extend_based_on_taxonomy
        # don't re-extend if this method has already been run
        return if extended_from_taxonomy
        # load taxonomy into temporary var
        temporary_taxonomy = taxonomy
        # if we don't have a taxonomy, but this has been built (e.g. from another instance)
        if metadata && metadata.taxonomy_class.present?
          # load the taxonomy class (typically NestedDb::Taxonomy)
          taxonomy_collection = metadata.taxonomy_class.constantize
          # if the collection is scoped
          if taxonomy_collection.scoped?
            # load the association based on the scope
            taxonomy_collection = metadata.scoped_type.constantize.find(metadata.scoped_id).taxonomies
          end
          # find the taxonomy by reference (e.g. articles)
          temporary_taxonomy ||= taxonomy_collection.where(:reference => metadata.taxonomy_reference).first
        end
        # loop through each property
        temporary_taxonomy.properties.each do |name,property|
          case property.data_type
          # if it's a has_many property
          when 'has_many'
            target_taxonomy = temporary_taxonomy.global_scope.where(:reference => property.association_taxonomy).first
            
            metaclass.class_eval <<-END
              has_many :#{property.name},
                :class_name         => 'NestedDb::Instance',
                :inverse_class_name => 'NestedDb::Instance',
                :inverse_of         => '#{property.association_property}',
                :foreign_key        => '#{property.association_property}_id',
                :taxonomy_reference => '#{property.association_taxonomy}',
                :taxonomy_class     => '#{temporary_taxonomy.class.name}',
                :scoped_type        => '#{temporary_taxonomy.scoped_type}',
                :scoped_id          => '#{temporary_taxonomy.scoped_id}',
                :source_id          => '#{id}'
              
              self.superclass.nested_attributes += [ "#{property.name}_attributes=" ]
              
              # load the relation before defining the method
              relation = relations['#{property.name}']
              define_method("#{property.name}_attributes=") do |attrs|
                t = NestedDb::Taxonomy.find('#{target_taxonomy.id}')
                attrs.each { |k,v|
                  attrs[k].merge!({ :taxonomy => t, :#{property.association_property} => id })
                }
                relation.nested_builder(attrs, :reject_if => Mongoid::NestedAttributes::ClassMethods::REJECT_ALL_BLANK_PROC, :allow_destroy => true).build(self)
              end
            END
          # if it's a belongs_to property
          when 'belongs_to'
            metaclass.class_eval <<-END
              belongs_to :#{property.name},
                :class_name         => 'NestedDb::Instance',
                :required           => #{property.required? ? 'true' : 'false'},
                :taxonomy_reference => '#{property.association_taxonomy}',
                :taxonomy_class     => '#{temporary_taxonomy.class.name}',
                :scoped_type        => '#{temporary_taxonomy.scoped_type}',
                :scoped_id          => '#{temporary_taxonomy.scoped_id}',
                :counter_cache      => true
            END
          # if it's a file property
          when 'file'
            # mount carrierwave
            metaclass.class_eval <<-END
              mount_uploader :#{property.name}, NestedDb::InstanceFileUploader
            END
          # if it's an image property
          when 'image'
            # mount carrierwave
            metaclass.class_eval <<-END
              mount_uploader :#{property.name}, NestedDb::InstanceImageUploader
            END
          # if it's a normal property (string etc)
          else
            metaclass.class_eval <<-END
              field :#{property.name},
                :type     => #{property.field_type.name},
                :required => #{property.required? ? 'true' : 'false'}
            END
            
            if 'money' == property.data_type
              metaclass.class_eval <<-END
                validates_numericality_of :#{property.name},
                  :greater_than_or_equal_to => 0
              END
            end
          end
        end # end loop through properties
        
        # if we have a source_id
        if metadata && metadata.inverse_of.present? && metadata.source_id.present?
          self.send(metadata.inverse_of, metadata.source_id)
        end
        
        # mark as extended
        self.extended_from_taxonomy = true
      end
    end
  end
end