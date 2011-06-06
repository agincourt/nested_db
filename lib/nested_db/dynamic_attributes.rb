require 'uri'

module NestedDb
  module DynamicAttributes
    def self.included(base)
      base.extend ClassMethods
      base.extend Associations
      base.send(:include, InstanceMethods)
      base.send(:include, Encryption)
      base.send(:include, Validation)

      # setup our callbacks
      base.class_eval do
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
      def email_regex
        /\A([-a-z0-9!\#$%&'*+\/=?^_`{|}~]+\.)*[-a-z0-9!\#$%&'*+\/=?^_`{|}~]+@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
      end

      def extend_from_taxonomy(taxonomy)
        taxonomy.properties.each do |name,property|
          case property.data_type
          when 'belongs_to', 'has_many', 'has_and_belongs_to_many'
            send("setup_#{property.data_type}_association", property)
          when 'file'
            mount_uploader property.name.to_sym, NestedDb::InstanceFileUploader
          when 'image'
            mount_uploader property.name.to_sym, NestedDb::InstanceImageUploader
          when 'password'
            password_field property.name, :required => property.required?
          else
            field property.name,
              :type     => property.field_type.name,
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

    module Associations
      def setup_belongs_to_association(property)
        setup_proxy(property)

        # getter
        define_method(property.name) do
          # try to load the cached variable
          result = instance_variable_get("@#{property.name}")
          # if we couldn't load it from the cache
          unless result
            # load the ID
            id = read_attribute(property.name)
            # try to find the association and cache
            result = instance_variable_set("@#{property.name}", retrieve_proxy(property.name).find(id)) if id
          end
          # return the result
          result
        end

        # setter
        define_method("#{property.name}=") do |value|
          self.write_attribute("#{property.name}_id", value.respond_to?(:id) ? value.id : value)
        end
      end

      def setup_has_many_association(property)
        setup_proxy(property)

        # getter
        define_method(property.name) do
          retrieve_proxy(property.name).getter
        end

        # nested attributes
        define_method("#{property.name}_attributes=") do |value|
          retrieve_proxy(property.name).write_attributes(value)
        end
      end

      def setup_has_and_belongs_to_many_association(property)
        setup_proxy(property)

        define_method("#{property.name}_ids=") do |ids|
          # default to empty array
          ids ||= []
          # set the instance variable
          instance_variable_set("@#{property.name}_ids", Array(ids))
          # write the attribute
          write_attribute("#{property.name}_ids", send("#{property.name}_ids"))
        end

        define_method("#{property.name}_ids") do
          # load the IDs
          ids = Array(
            instance_variable_get("@#{property.name}_ids") ||
            read_attribute("#{property.name}_ids")
          )
          # parse into BSON
          ids.
            delete_if { |id| !id.kind_of?(BSON::ObjectId) && !BSON::ObjectId.legal?(id) }.
            map { |id| id.kind_of?(BSON::ObjectId) ? id : BSON::ObjectId(id) }.
            uniq
        end

        define_method(property.name) do
          retrieve_proxy(property.name).getter.any_in(:_id => send("#{property.name}_ids"))
        end
      end

      def setup_proxy(property)
        # setup default hash to store proxies
        self.proxies ||= {}
        # merge in this association
        self.proxies.merge!({
          property.name.to_sym => Proc.new { |obj|
            Proxy.from(obj).to(property.name).using(property.data_type)
          }
        })
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