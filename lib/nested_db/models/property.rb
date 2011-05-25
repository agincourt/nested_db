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
          
          # scopes
          scope :ordered, order_by(:index.asc).order_by(:name.asc)
          
          # validation
          validates_presence_of   :name
          validates_uniqueness_of :name,
            :scope => :taxonomy
          validates_format_of     :name,
            :with    => /^[a-z0-9\_]*$/i,
            :message => 'can only contain letters, digits, hyphons and underscores'
          validates_format_of     :name,
            :with    => /^[a-z]+/i,
            :message => 'must start with an alphabetic letter'
          validates_presence_of   :data_type
          
          # callbacks
          before_validation :downcase_name
        end
        base.send(:include, InstanceMethods)
      end
      
      module InstanceMethods
        def field_type
          self.class.data_types[data_type.to_sym] || String
        end
        
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