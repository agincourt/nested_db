require 'digest/sha2'

module NestedDb
  module Validation
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.extend ClassMethods
      base.class_eval do
        cattr_accessor :unique_taxonomy_attributes
        
        validate :validate_uniqueness_within_taxonomies,
          :if => proc { |obj| obj.taxonomy.present? }
      end
    end
    
    module ClassMethods
      def validates_uniqueness_within_taxonomy_of(attr)
        unique_taxonomy_attributes ||= []
        unique_taxonomy_attributes  << attr
      end
    end
    
    module InstanceMethods
      private
      def validate_uniqueness_within_taxonomies
        (self.class.unique_taxonomy_attributes || []).each do |attribute|
          errors.add(
            attribute,
            :taken,
            { :value => value }
          ) unless valid_uniquely_within_taxonomy?(attribute)
        end
      end
      
      def valid_uniquely_within_taxonomy?(attribute)
        # load our attribute value
        value = attributes[attribute]
        value = Regexp.new("^#{Regexp.escape(value.to_s)}$", Regexp::IGNORECASE) if value
        # find in the taxonomy
        criteria = taxonomy.instances.where(attribute => value)
        criteria = criteria.where(:_id => { '$ne' => id }) if persisted?
        # check none were found
        criteria.count == 0
      end
    end
  end
end