require 'digest/sha2'

module NestedDb
  module Validation
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        attr_accessor :unique_taxonomy_attributes
        
        validate :ensure_uniqueness_within_taxonomies,
          :if => proc { |obj| obj.taxonomy.present? }
      end
    end
    
    module InstanceMethods
      private
      def validates_uniqueness_within_taxonomy_of(attr)
        self.unique_taxonomy_attributes ||= []
        self.unique_taxonomy_attributes  << attr
      end
      
      def ensure_uniqueness_within_taxonomies
        (unique_taxonomy_attributes || []).uniq.each do |attribute|
          self.errors.add(
            attribute,
            :taken,
            { :value => attributes[attribute] }
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