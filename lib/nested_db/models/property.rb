module NestedDb
  module Models
    module Property
      def self.included(base)
        base.class_eval do
          # fields
          field :name
          field :data_type
          field :label
          field :index, :type => Integer, :default => 0, :required => true
          
          # associations
          embedded_in :taxonomy, :inverse_of => name.underscore.pluralize
          
          # scopes
          scope :ordered, order_by(:index.asc, :name.asc)
          
          # validation
          validates_presence_of   :name
          validates_uniqueness_of :name,
            :scope => :taxonomy
          validates_format_of     :name,
            :with    => /^[a-z]+[a-z0-9]*$/i,
            :message => 'can only contain letters and digits (must not start with a digit)'
          validates_presence_of   :data_type
          
          # callbacks
          before_validation :downcase_name
        end
        base.send(:include, InstanceMethods)
      end
      
      module InstanceMethods
        def label
          read_attribute(:label) || read_attribute(:name)
        end
        
        private  
        def downcase_name
          self.name.try(:downcase!)
        end
      end
    end
  end
end