module NestedDb
  class TaxonomyDrop < ::Liquid::Drop
    attr_accessor :taxonomy
    
    def initialize(taxonomy)
      self.taxonomy = taxonomy
      
      taxonomy.property_fields.each { |f|
        self.class.send(:define_method, "find_by_#{f.name.to_s}") do |value|
          taxonomy.instances.where({ f.name => value }).limit(100).map { |i|
            InstanceDrop.new(i, self)
          }
        end
      }
    end
  
    def name
      taxonomy.name
    end
  
    def all
      taxonomy.instances.limit(100).map { |i|
        InstanceDrop.new(i, self)
      }
    end
    
    def count
      taxonomy.instances.count
    end
  
    def fields
      taxonomy.instances.build.fields.keys
    end
  end
end