module NestedDb
  class InstanceDrop < ::Liquid::Drop
    attr_accessor :taxonomy_instance
    attr_accessor :taxonomy_drop
    
    delegate :read_attribute, :to => "taxonomy_instance"
    
    def initialize(instance, taxonomy_drop = nil)
      self.taxonomy_instance = instance
      self.taxonomy_drop     = taxonomy_drop if taxonomy_drop
    
      # loop through fields
      fields.each do |k|
        self.class.send(:define_method, k.to_sym) do
          read_attribute(k)
        end                                                                                                                                                                        
      end
    end
    
    def fields
      taxonomy_instance.fields.keys
    end
    
    def taxonomy
      self.taxonomy_drop ||= TaxonomyDrop.new(taxonomy_instance.taxonomy)
    end
    
    def to_liquid
      {
        'fields'   => fields,
        'taxonomy' => taxonomy
      }.merge(fields.inject({}) { |hash, f| hash.merge!(f => read_attribute(f)) })
    end
  end
end