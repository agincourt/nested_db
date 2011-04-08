module NestedDb
  module DataTypes
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      # returns a hash of the datatype name, then it's stored data type
      def data_types
        {
          :array      => Array,
          :decimal    => Float,
          :boolean    => Boolean,
          :date       => Date,
          :datetime   => DateTime,
          :hash       => Hash,
          :integer    => Integer,
          :string     => String,
          :time       => Time,
          :has_many   => nil,
          :has_one    => nil,
          :belongs_to => BSON::ObjectId
        }
      end
      
      # returns an array of datatype name
      def available_data_types
        data_types.keys.map(&:to_s)
      end
    end
    
  end
end