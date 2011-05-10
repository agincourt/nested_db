module NestedDb
  module DynamicAttributes
    def self.included(base)
      base.extend ClassMethods
      base.send(:include, InstanceMethods)
      # setup our callbacks
      base.class_eval do
        
        attr_accessor :extended_from_taxonomy,
                      :nested_instance_attributes
        
        # validation
        validate :validate_nested_attributes
        
        # callbacks
        after_build do
          extend_based_on_taxonomy
        end
        
        after_initialize do
          extend_based_on_taxonomy if taxonomy
        end
        
        after_save :save_nested_attributes
        
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
      
      def nested_attributes
        super + (nested_instance_attributes || {}).map { |k,v| "#{k.to_s}_attributes=" }
      end
      
      def uploaders
        metaclass.uploaders
      end
      
      def uploader_options
        metaclass.uploader_options
      end
      
      def taxonomy=(value)
        super(value)
        extend_based_on_taxonomy
      end
      
      # dynamically adds fields for each of the taxonomy's properties
      def extend_based_on_taxonomy
        # don't re-extend if this method has already been run
        return if extended_from_taxonomy
        # if we have metadata and it's got an after_build property
        if metadata && metadata.after_build
          metadata.after_build.call(self)
        end
        # load taxonomy into temporary var
        temporary_taxonomy = taxonomy
        # if we don't have a taxonomy, but this has been built (e.g. from another instance)
        if !temporary_taxonomy && metadata && metadata.taxonomy_class.present?
          # load the taxonomy
          t = metadata.taxonomy_class.constantize.find(metadata.taxonomy_id)
          # set it
          temporary_taxonomy = t
        end
        # check we have a taxonomy
        raise StandardError, "No taxonomy" unless temporary_taxonomy
        # loop through each property
        temporary_taxonomy.properties.each do |name,property|
          case property.data_type
          # if it's a has_many property
          when 'has_many'
            # load the target taxonomy
            target_taxonomy = temporary_taxonomy.global_scope.where(:reference => property.association_taxonomy).first
            # only allow the relation if we found the target
            if target_taxonomy
              metaclass.class_eval <<-END
                has_many :#{property.name},
                  :class_name         => '#{self.class.name}',
                  :inverse_class_name => '#{self.class.name}',
                  :inverse_of         => '#{property.association_property}',
                  :foreign_key        => '#{property.association_property}_id',
                  :taxonomy_id        => '#{target_taxonomy.id}',
                  :taxonomy_class     => '#{target_taxonomy.class.name}',
                  :source_id          => '#{id}',
                  :after_build        => proc { |obj|
                    # set the taxonomy
                    obj.taxonomy = #{target_taxonomy.class.name}.find('#{target_taxonomy.id}')
                    # load the taxonomy properties
                    obj.send(:extend_based_on_taxonomy)
                    # set the association if persisted
                    #{ "obj.#{property.association_property} ||= #{self.class.name}.find('#{id}')" if persisted? }
                  }
                
                # define the method for accepting the nested_attributes
                define_method("#{property.name}_attributes=") do |attrs|
                  # setup a blank hash
                  self.nested_instance_attributes ||= {}
                  # setup our nested object
                  ni = NestedDb::NestedInstances.new(
                    self,
                    {
                      :taxonomy   => #{target_taxonomy.class.name}.find('#{target_taxonomy.id}'),
                      :attributes => attrs,
                      :inverse_of => '#{property.association_property}'
                    }
                  )
                  # merge in to the hash
                  self.nested_instance_attributes.merge!(:#{property.name} => ni)
                  # update our instance of the objects
                  @#{property.name} = ni.objects
                end
              END
            end
          # if it's a belongs_to property
          when 'belongs_to'
            target_taxonomy = temporary_taxonomy.global_scope.where(:reference => property.association_taxonomy).first
            
            metaclass.class_eval <<-END
              belongs_to :#{property.name},
                :class_name     => '#{self.class.name}',
                :required       => #{property.required? ? 'true' : 'false'},
                :taxonomy_id    => '#{target_taxonomy.id}',
                :taxonomy_class => '#{target_taxonomy.class.name}',
                :scoped_type    => '#{temporary_taxonomy.scoped_type}',
                :scoped_id      => '#{temporary_taxonomy.scoped_id}',
                :counter_cache  => true
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
          self.send(metadata.inverse_of.gsub(/\=+$/, '='), metadata.source_id)
        end
        
        # mark as extended
        self.extended_from_taxonomy = true
      end
      
      protected
      # validates the nested_attributes and
      # adds an error to the root object if they are invalid
      def validate_nested_attributes
        self.nested_instance_attributes.each { |k,v|
          self.errors.add(k, "are invalid") unless v.valid_as_nested?
        } if self.nested_instance_attributes
      end
      
      # saves each nested_attribute after
      # passing this object's id to it
      def save_nested_attributes
        self.nested_instance_attributes.each { |k,v|
          # pass our saved id to the object
          v.parent = self
          # save the object
          v.save
        } if self.nested_instance_attributes
      end
    end
  end
end