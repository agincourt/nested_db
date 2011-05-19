require "spec_helper"

describe NestedDb::Taxonomy do
  describe "liquid templating" do
    let(:taxonomy) do
      return @taxonomy if defined?(@taxonomy)
      # wipe all taxonomies
      NestedDb::Taxonomy.delete_all
      # create the taxonomy
      @taxonomy = NestedDb::Taxonomy.create!({
        :name      => 'Category',
        :reference => 'categories'
      })
      # add a normal property
      @taxonomy.physical_properties.create!({
        :name      => 'title',
        :data_type => 'string'
      })
      # return
      @taxonomy
    end
    
    it "should respond to liquidized methods" do
      tax = taxonomy
      ['to_liquid', 'liquid_drop', 'liquid_drop_class'].each do |method|
        tax.should respond_to method
      end
      tax.liquid_drop_class.should == NestedDb::TaxonomyDrop
      tax.liquid_drop.class.should == NestedDb::TaxonomyDrop
      [NestedDb::TaxonomyDrop, Hash].should include tax.to_liquid.class
    end
  end
end