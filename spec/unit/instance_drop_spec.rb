require "spec_helper"

describe NestedDb::InstanceDrop do
  context "when an instance is ported to a drop" do
    let(:taxonomy) do
      return @taxonomy if defined?(@taxonomy)
      # wipe all taxonomies
      NestedDb::Taxonomy.delete_all
      # create the taxonomy
      @taxonomy = NestedDb::Taxonomy.create!({
        :name      => 'Category',
        :reference => 'categories'
      })
      # add a file property
      @taxonomy.physical_properties.create!({
        :name      => 'name',
        :data_type => 'string',
        :required  => true
      })
      # return
      @taxonomy
    end

    let(:instance) do
      @instance ||= taxonomy.instances.create({ 
        :name => 'Test'
      })
    end
    
    it "should load the properties from the taxonomy" do
      inst = instance
      drop = NestedDb::InstanceDrop.new(inst)
      drop.should respond_to 'to_liquid'
      (inst.taxonomy.properties.keys + ['id', 'taxonomy', 'created_at', 'updated_at']).each do |key|
        drop.to_liquid.keys.should include(key)
      end
    end
    
    it "should return a drop for it's taxonomy" do
      inst = instance
      drop = NestedDb::InstanceDrop.new(inst)
      drop.should respond_to 'taxonomy'
      drop.taxonomy.class.should == NestedDb::TaxonomyDrop
    end
  end
end