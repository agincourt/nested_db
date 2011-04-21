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
          :integer    => Integer,
          :string     => String,
          :rich_text  => String,
          :plain_text => String,
          :time       => Time,
          :file       => String
        }
      end
      
      # returns an array of datatype name
      def available_data_types
        data_types.keys.map(&:to_s)
      end
    end
    
  end
end