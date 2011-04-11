module NestedDb
  class TaxonomyDrop < ::Liquid::Drop
    attr_accessor :taxonomy
    
    def initialize(taxonomy)
      self.taxonomy = taxonomy
      
      taxonomy.property_fields.each { |k,v|
        self.class.send(:define_method, "find_all_by_#{k.to_s}") do |value|
          taxonomy.instances.where({ k => value }).limit(100).map { |i|
            InstanceDrop.new(i, self)
          }
        end
        
        self.class.send(:define_method, "find_one_by_#{k.to_s}") do |value|
          instance = taxonomy.instances.where({ k => value }).find(:first)
          InstanceDrop.new(instance, self) if instance
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