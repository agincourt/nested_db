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
      # add a normal property
      @taxonomy.physical_properties.create!({
        :name      => 'name',
        :data_type => 'string',
        :required  => true
      })
      # create the second taxonomy to relate to
      @taxonomy_two = NestedDb::Taxonomy.create!({
        :name      => 'Article',
        :reference => 'articles'
      })
      # add a normal property to articles
      @taxonomy_two.physical_properties.create!({
        :name      => 'name',
        :data_type => 'string',
        :required  => true
      })
      # add a belongs relation from taxonomy two to taxonomy one
      @taxonomy_two.physical_properties.create!({
        :name                 => 'category',
        :data_type            => 'belongs_to',
        :association_property => 'name',      # just used for display
        :association_taxonomy => 'categories' # based on reference
      })
      # add a image property to categories
      @taxonomy.physical_properties.create!({
        :name      => 'image',
        :data_type => 'image',
        :image_versions_attributes => {
          "0" => { :name => 'square', :width => 200, :height => 200, :operation => 'resize_to_fit' }
        }
      })
      # add a has_many relation from taxonomy one to taxonomy two
      @taxonomy.physical_properties.create!({
        :name                 => 'articles',
        :data_type            => 'has_many',
        :association_property => 'category', # used for relation
        :association_taxonomy => 'articles'  # based on reference
      })
      @taxonomy
    end

    let(:instance) do
      @instance ||= taxonomy.instances.create({ 
        :name => 'Test'
      })
    end
    
    def file(name)
      ActionDispatch::Http::UploadedFile.new(
        :filename => "rails.png", 
        :type => "image/png", 
        :head => "Content-Disposition: form-data;
                  name=\"#{name}\"; 
                  filename=\"rails.png\" 
                  Content-Type: image/png\r\n",
        :tempfile => File.new(file_path)
      )
    end
    
    let(:file_path) do
      File.join(File.dirname(__FILE__), 'image.png')
    end
    
    it "should load the properties from the taxonomy" do
      inst = instance
      drop = NestedDb::InstanceDrop.new(inst)
      drop.should respond_to 'to_liquid'
      (inst.taxonomy.properties.keys + ['id', 'taxonomy', 'created_at', 'updated_at']).each do |key|
        drop.to_liquid.keys.should include(key)
      end
    end
    
    it "should load the associations from the taxonomy" do
      inst = instance
      inst.update_attributes({
        :articles_attributes => { '0' => {
          'name' => 'Test 2'
        } }
      })
      inst.articles.size.should == 1
      inst.articles.first.persisted?.should == true
      inst.articles.first.category.should == inst
      drop = NestedDb::InstanceDrop.new(inst)
      drop.to_liquid.keys.should include('articles')
      drop.to_liquid['articles'].size.should     == 1
      drop.to_liquid['articles'][0].class.should == NestedDb::InstanceDrop
      drop.to_liquid['articles'][0].to_liquid['category'].instance.should == drop.instance
    end
    
    it "should return a drop for it's taxonomy" do
      inst = instance
      drop = NestedDb::InstanceDrop.new(inst)
      drop.should respond_to 'taxonomy'
      drop.taxonomy.class.should == NestedDb::TaxonomyDrop
    end
    
    it "should return nil for empty file fields" do
      NestedDb::InstanceDrop.new(instance).to_liquid['image'].should be_nil
    end
    
    it "should return a string for populated file fields" do
      inst = instance
      inst.update_attributes(:image => file('image')).should == true
      inst.image.url.should_not be_nil
      NestedDb::InstanceDrop.new(inst).to_liquid['image'].should_not be_nil
    end
  end
end