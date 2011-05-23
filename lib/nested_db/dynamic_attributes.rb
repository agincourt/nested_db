require 'uri'

module NestedDb
  module DynamicAttributes
    def self.included(base)
      base.extend ClassMethods
      base.send(:include, InstanceMethods)
      base.send(:include, Encryption)
      
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
                  :dependent          => :destroy,
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
                      :taxonomy         => #{target_taxonomy.class.name}.find('#{target_taxonomy.id}'),
                      :attributes       => attrs,
                      :inverse_of       => '#{property.association_property}',
                      :association_name => '#{property.name}'
                    }
                  )
                  # merge in to the hash
                  self.nested_instance_attributes.merge!(:#{property.name} => ni)
                end
              END
            end
          # if it's a has_and_belongs_to_many property
          when 'has_and_belongs_to_many'
            target_taxonomy = temporary_taxonomy.global_scope.where(:reference => property.association_taxonomy).first
            # only allow the relation if we found the target
            if target_taxonomy
              metaclass.class_eval <<-END
                after_save :ensure_correct_remote_#{property.name}_ids
              
                def #{property.name}_ids=(ids = [])
                  instance_variable_set(:@#{property.name}_ids, Array(ids))
                  write_attribute(:#{property.name}_ids, #{property.name}_ids)
                end
                
                def #{property.name}_ids
                  # pull from DB or setup default array
                  @#{property.name}_ids ||= Array(read_attribute(:#{property.name}_ids) || [])
                  # parse into BSON::ObjectIds
                  @#{property.name}_ids.delete_if { |id|
                    # ensure we only use legal objectids
                    !id.kind_of?(BSON::ObjectId) && !BSON::ObjectId.legal?(id)
                  }.map { |id|
                    # change from strings into objectids
                    id.kind_of?(BSON::ObjectId) ? id : BSON::ObjectId(id)
                  }.uniq # ensure unique
                end
                
                def #{property.name}
                  remote_#{property.name}_taxonomy.instances.any_in(:_id => #{property.name}_ids)
                end
                
                def remote_#{property.name}_taxonomy
                  @remote_#{property.name}_taxonomy ||= taxonomy.global_scope.where(:reference => '#{property.association_taxonomy}').first
                end
                
                private
                def ensure_correct_remote_#{property.name}_ids
                  remove_from_remote_#{property.name}
                  add_to_remote_#{property.name}
                end
                
                def remove_from_remote_#{property.name}
                  # find all the instances which contain this id but shouldn't
                  criteria = remote_#{property.name}_taxonomy.instances.
                    where(:#{temporary_taxonomy.reference}_ids => id).
                    not_in(:_id => #{property.name}_ids).
                    where(:"#{temporary_taxonomy.reference}_ids".exists => true)
                  
                  # update them to remove it
                  criteria.klass.collection.update(
                    criteria.selector,
                    { '$pull' => { :"#{temporary_taxonomy.reference}_ids" => id } },
                    :multi => true,
                    :safe => Mongoid.persist_in_safe_mode
                  )
                end
                
                def add_to_remote_#{property.name}
                  # find all the instances which should contain this ID
                  criteria = remote_#{property.name}_taxonomy.instances.
                    any_in(:_id => #{property.name}_ids)
                  
                  # update them to add it
                  criteria.klass.collection.update(
                    criteria.selector,
                    { '$addToSet' => { "#{temporary_taxonomy.reference}_ids" => id } },
                    :multi => true,
                    :safe => Mongoid.persist_in_safe_mode
                  )
                end
              END
            end
          # if it's a belongs_to property
          when 'belongs_to'
            target_taxonomy = temporary_taxonomy.global_scope.where(:reference => property.association_taxonomy).first
            # only allow the relation if we found the target
            if target_taxonomy
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
            end
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
          # if it's a password property
          when 'password'
            metaclass.class_eval <<-END
              password_field :#{property.name},
                :required => #{property.required? ? 'true' : 'false'}
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
          
          if property.unique?
            metaclass.class_eval <<-END
              validates_uniqueness_of :#{property.name},
                :scope => :taxonomy_id
            END
          end
          
          case property.format
          when 'email'
            metaclass.class_eval <<-END
              validates_format_of :#{property.name},
                :with    => URI.regexp,
                :message => 'must be a valid email address'
            END
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