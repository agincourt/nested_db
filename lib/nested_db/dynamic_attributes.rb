require 'uri'

module NestedDb
  module DynamicAttributes
    def self.included(base)
      base.extend ClassMethods
      base.send(:include, Encryption)
    end

    module ClassMethods
      def email_regex
        /\A([-a-z0-9!\#$%&'*+\/=?^_`{|}~]+\.)*[-a-z0-9!\#$%&'*+\/=?^_`{|}~]+@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
      end

      def extend_from_taxonomy(taxonomy)
        # loop through each property
        taxonomy.properties.each do |name,property|
          # setup based on the type of property
          case property.data_type
          when 'belongs_to'
            belongs_to property.name,
              :class_name => "Instance#{property.taxonomy_id}"
          when 'has_many'
            has_many property.name,
              :class_name => "Instance#{property.taxonomy_id}",
              :inverse_of => property.foreign_key
            accepts_nested_attributes_for property.name,
              :allow_destroy => true,
              :reject_if     => :all_blank
          when 'has_and_belongs_to_many'
            has_and_belongs_to_many property.name,
              :class_name => "Instance#{property.taxonomy_id}",
              :inverse_of => property.foreign_key
            unless property.name == property.name.singularize
              define_method("#{property.name}_ids=") do |ids|
                # load the association
                assoc = self.class.reflect_on_association(property.name)
                # save the values
                self.send("#{property.name}=", assoc.class_name.constantize.any_in(:_id => ids))
              end
              alias_method :"#{property.name}_ids", :"#{property.name.singularize}_ids"
            end
          when 'file'
            mount_uploader property.name, NestedDb::InstanceFileUploader
          when 'image'
            mount_uploader property.name, NestedDb::InstanceImageUploader
          when 'password'
            password_field property.name, :required => property.required?
          else
            field property.name,
              :type     => property.field_type,
              :required => property.required?
          end

          # numeric
          if 'money' == property.data_type
            validates_numericality_of property.name,
              :greater_than_or_equal_to => 0
          end

          # uniqueness
          if property.unique?
            validates_uniqueness_of property.name, :case_sensitive => false
          end

          # formating
          case property.format
          when 'email'
            validates_format_of property.name,
              :with        => email_regex,
              :message     => 'must be a valid email address',
              :allow_blank => true
          end
        end
      end
    end
  end
end