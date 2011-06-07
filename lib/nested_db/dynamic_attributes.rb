require 'uri'

module NestedDb
  module DynamicAttributes
    def self.included(base)
      base.extend ClassMethods
      base.send(:include, InstanceMethods)
      base.send(:include, Encryption)
      base.send(:include, Validation)

      # setup our callbacks
      base.class_eval do
        cattr_accessor :class_name
        cattr_accessor :proxies # raw procs
        attr_accessor  :processed_proxies # processed values

        # validation
        validate :proxies_should_be_valid

        # callbacks
        after_initialize :process_proxies
        after_save       :update_remote_habtm_associations
        after_destroy    :remove_from_all_remote_habtm_associations
      end
    end

    module ClassMethods
      def identify(name)
        self.class_name = name
      end

      def name
        class_name || super
      end

      def email_regex
        /\A([-a-z0-9!\#$%&'*+\/=?^_`{|}~]+\.)*[-a-z0-9!\#$%&'*+\/=?^_`{|}~]+@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
      end

      def build_associations
        relations.each do |name,metadata|
          if metadata.taxonomy_id.present?
            Instances.find_or_create(metadata.taxonomy_id)
          end
        end
      end

      def extend_from_taxonomy(taxonomy)
        taxonomy.properties.each do |name,property|
          case property.data_type
          when 'belongs_to'
            belongs_to property.name,
              :class_name  => Instances.klass_name(property.taxonomy_id),
              :taxonomy_id => property.taxonomy_id
          when 'has_many'
            has_many property.name,
              :class_name  => Instances.klass_name(property.taxonomy_id),
              :inverse_of  => property.association_property,
              :taxonomy_id => property.taxonomy_id
          when 'has_and_belongs_to_many'
            has_and_belongs_to_many property.name,
              :class_name  => Instances.klass_name(property.taxonomy_id),
              :inverse_of  => property.foreign_key,
              :taxonomy_id => property.taxonomy_id
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
            validate_uniqueness_of property.name
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

    module InstanceMethods
      private
      # returns a Proxy object for the passed name
      def retrieve_proxy(name)
        processed_proxies[name.to_sym]
      end

      def process_proxies
        # setup default hash for proxy values
        self.processed_proxies ||= {}
        # loop through each proxy
        (self.class.proxies || {}).each do |name,proxy|
          # if it's a proc - call it
          self.processed_proxies.merge!(name => proxy.call(self))
        end
      end

      def proxies_should_be_valid
        # loop through each proxy
        processed_proxies.each do |name,proxy|
          # if it's invalid
          unless proxy.valid?
            # add an error to this object
            self.errors.add(name, "#{proxy.many? ? 'are' : 'is'} invalid")
          end
        end
      end

      # synchronises HABTM associations by removing or adding
      # this object's id to remote objects
      def update_remote_habtm_associations
        processed_proxies.each do |name,proxy|
          proxy.synchronise(send("#{name}_ids")) if proxy.habtm?
        end
      end

      # removes this object's id from all remote HABTM
      # used when an object is destroyed
      def remove_from_all_remote_habtm_associations
        processed_proxies.each do |name,proxy|
          proxy.remove_from_all_remote_habtm_associations if proxy.habtm?
        end
      end
    end
  end
end