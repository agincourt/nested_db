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
          :data_type => 'file'
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
        # add a normal property
        @taxonomy_two.physical_properties.create!({
          :name      => 'name',
          :data_type => 'string'
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
        instance.metaclass.name.should        == 'NestedDb::Instance'
      end
      
      it "should return a selection criteria for the relation" do
        instance.articles.class.should == Array
      end
      
      it "should be able to build related instances" do
        inst = instance
        inst.articles.build.category.should == inst
      end
      
      it "should be able to create related instances" do
        instance.should respond_to 'articles_attributes='
        instance.class.relations.keys.should include 'articles'
        instance.update_attributes({
          'articles_attributes' => { '0' => { 'name' => 'Test' } }
        }).should == true
      end
    end
  end
  
end