require "spec_helper"

describe NestedDb::Instance do
  
  describe "file uploads" do
    context "when the instance's taxonomy defines a file field" do
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
          :name      => 'image',
          :data_type => 'image',
          :required  => true,
          :image_versions_attributes => {
            "0" => { :name => 'square', :width => 200, :height => 200, :operation => 'resize_to_fit' },
            "1" => { :name => 'image',  :width => 540, :height => 200, :operation => 'resize_to_fill' }
          }
        })
        # return
        @taxonomy
      end
      
      let(:instance) do
        @instance ||= taxonomy.instances.build
      end
      
      it "should relay the uploaders from the metaclass" do
        instance.should respond_to 'uploaders'
        instance.uploaders.keys.should include :image
      end
      
      it "should relay the uploader_options from the metaclass" do
        instance.should respond_to 'uploader_options'
        instance.uploaders.keys.should include :image
      end
      
      it "should respond to image methods" do
        instance.should respond_to 'image='
        instance.should respond_to 'image'
        instance.image.should respond_to 'url'
        instance.image.should respond_to 'versions'
      end
      
      it "should have an image version called 'square' and one for the mounted_as property loaded from the instance model" do
        inst = instance
        inst.image.versions.keys.should include :square
        inst.image.versions.keys.should include :image
        inst.image.versions[:square].version_name.should == :square
        inst.image.versions[:square].class.should == NestedDb::InstanceImageUploader
        [String, NilClass].should include inst.image.url(:square).class
      end
      
      it "should accept a new image" do
        file = File.join(File.dirname(__FILE__), 'image.png')
        File.exist?(file).should == true
        instance.image = File.new(file)
      end
    end
  end
  
  describe "has_many relationships" do
    context "when the instance's taxonomy defines a has_many association" do
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
        # add a image property to articles
        @taxonomy_two.physical_properties.create!({
          :name      => 'image',
          :data_type => 'image',
          :required  => true
        })
        # add a belongs relation from taxonomy two to taxonomy one
        @taxonomy_two.physical_properties.create!({
          :name                 => 'category',
          :data_type            => 'belongs_to',
          :association_property => 'title',     # just used for display
          :association_taxonomy => 'categories' # based on reference
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
        @instance ||= taxonomy.instances.create!({ :title => 'Test' })
      end
      
      let(:file) do
        @file ||= File.join(File.dirname(__FILE__), 'image.png')
      end
      
      it "should have a taxonomy with an articles property" do
        instance.taxonomy.has_property?(:articles).should == true
      end
      
      it "should have been extended from the taxonomy" do
        instance.extended_from_taxonomy.should == true
      end
      
      it "should respond to #articles" do
        instance.should respond_to :articles
      end
      
      it "should have an association named 'articles' on the metaclass" do
        instance.metaclass.relations.keys.should include 'articles'
      end
      
      it "should return the metadata for the relation" do
        # load the association metadata
        association = instance.metaclass.reflect_on_association(:articles)
        # check it
        association.should_not                == nil
        association.class_name.should         == 'NestedDb::Instance'
        association.foreign_key.should        == 'category_id'
        association.inverse_class_name.should == 'NestedDb::Instance'
        association.taxonomy_class.should     == 'NestedDb::Taxonomy'
        association.taxonomy_id.should_not    be_blank
        instance.metaclass.name.should        == 'NestedDb::Instance'
      end
      
      it "should return a selection criteria for the relation" do
        instance.should respond_to 'articles'
        instance.articles.class.should == Array
      end
      
      it "should pass on itself to new related instances" do
        inst = instance
        inst = inst.class.find(inst.id)
        article = inst.articles.build
        article.category.should == inst
      end
      
      it "should pass the correct taxonomy to new related instances" do
        inst = instance
        article = inst.articles.build
        article.taxonomy.should_not be_nil
        article.taxonomy.reference.should == 'articles'
      end
      
      it "should respond to the correct methods when built from a parent object" do
        article = instance.articles.build
        article.should respond_to 'name'
        article.should respond_to 'name='
        article.should respond_to 'image'
        article.should respond_to 'image='
        article.image.class.should == NestedDb::InstanceImageUploader
        article.image = File.new(file)
        article.name  = "testing123"
        article.save
        article.errors.should be_empty
      end
      
      it "should be able to create related instances" do
        # ensure the file is okay
        CarrierWave::SanitizedFile.new(file).should_not be_empty
        # create our instance
        inst = instance
        # ensure it responds to the nested attributes creator
        inst.should respond_to 'articles_attributes='
        # update the instance with an article
        inst.articles_attributes = {
          '0' => {
            'name'  => 'Test',
            'image' => File.new(file)
          },
          '1' => {
            'name'  => 'Test',
            'image' => File.new(file)
          }
        }
        # ensure we have one article
        inst.articles.size.should == 2
        # ensure the article's taxonomy was set
        inst.articles.first.taxonomy.should_not be_nil
        # save
        inst.save.should == true
        # ensure the article is valid
        inst.articles.each { |a|
          a.name.should == 'Test'
          a.image.should_not be_nil
          a.image.class.should == NestedDb::InstanceImageUploader
          a.image.file.should_not be_nil
          a.image?.should == true
          a.image.should respond_to 'url'
          a.errors.should == {}
        }
        inst.errors.should == {}
      end
      
      it "should be able to update related instances" do
        # create our instance
        inst = instance
        # update the instance with an article
        inst.update_attributes(:articles_attributes => {
          '0' => {
            'name'  => 'Test',
            'image' => File.new(file)
          },
          '1' => {
            'name'  => 'Test',
            'image' => File.new(file)
          }
        })
        # ensure we have 2 articles
        inst.articles.size.should == 2
        inst.articles.first.persisted?.should == true
        # update the article
        inst.update_attributes(:articles_attributes => {
          '0' => {
            'id'    => inst.articles.first.id,
            'name'  => 'Test 2',
            'image' => File.new(file)
          },
          '1' => {
            'id'       => inst.articles.last.id,
            '_destroy' => '1'
          }
        })
        # ensure the article's name has changed
        inst.articles.first.name.should == 'Test 2'
        # TODO: ensure the second article was deleted
        inst.articles.size.should == 1
      end
    end
  end
  
end