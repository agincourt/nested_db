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
        inst.image.versions[:square].class.should == NestedDb::InstanceVersionUploader
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
          :required  => true,
          :image_versions_attributes => {
            "0" => { :name => 'square', :width => 200, :height => 200, :operation => 'resize_to_fit' }
          }
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
        article.image = file('image')
        article.name  = "testing123"
        article.save
        article.errors.should be_empty
      end
      
      it "should be able to create related instances" do
        # ensure the file is okay
        CarrierWave::SanitizedFile.new(file_path).should_not be_empty
        # create our instance
        inst = instance
        # ensure it responds to the nested attributes creator
        inst.should respond_to 'articles_attributes='
        # update the instance with an article
        inst.articles_attributes = {
          '0' => {
            'name'  => 'Test',
            'image' => file('image')
          },
          '1' => {
            'name'  => 'Test',
            'image' => file('image')
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
            'image' => file('image')
          },
          '1' => {
            'name'  => 'Test',
            'image' => file('image')
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
            'image' => file('image')
          },
          '1' => {
            'id'       => inst.articles.last.id,
            '_destroy' => '1'
          }
        })
        # ensure the article's name has changed
        inst.articles.first.name.should == 'Test 2'
        # TODO: ensure the second article was deleted
        # inst.articles.size.should == 1
      end
      
      it "should be able to create nested instances during it's own creation" do
        inst = taxonomy.instances.build
        inst.write_attributes({
          :title => 'Test',
          :articles_attributes => {
            '0' => {
              'name'  => 'Test 2',
              'image' => file('image')
            }
          }
        })
        inst.save
        # ensure we have 1 article
        inst.articles.size.should == 1
        # ensure the article has the category set
        inst.articles.first.category.should == inst
      end
      
      context "liquid templating" do
        it "should be able to reference associated instances" do
          inst = taxonomy.instances.build
          inst.write_attributes({
            :title => 'Test',
            :articles_attributes => {
              '0' => {
                'name'  => 'Test 2',
                'image' => file('image')
              }
            }
          })
          inst.save
          inst.to_liquid.articles.should respond_to 'each'
        end
      end
    end
  end
  
  describe "has_and_belongs_to_many relationships" do
    context "when the instance's taxonomy defines a has_and_belongs_to_many association" do
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
        # add a has_and_belongs_to_many relation from taxonomy two to taxonomy one
        @taxonomy_two.physical_properties.create!({
          :name                 => 'categories',
          :data_type            => 'has_and_belongs_to_many',
          :association_taxonomy => 'categories' # based on reference
        })
        # add a has_and_belongs_to_many relation from taxonomy one to taxonomy two
        @taxonomy.physical_properties.create!({
          :name                 => 'articles',
          :data_type            => 'has_and_belongs_to_many',
          :association_taxonomy => 'articles' # based on reference
        })
        @taxonomy
      end
      
      let(:instance) do
        @instance ||= taxonomy.instances.create!({ :name => 'Test' })
      end
      
      it "should load the relation from the taxonomy" do
        inst = instance
        # create another instance in the same taxonomy
        inst.taxonomy.instances.create!({ :name => 'Test 2' })
        # instances should respond to their relationship getter method
        inst.should respond_to 'articles'
        # instances should respond to their relationship ids setter method
        inst.should respond_to 'articles_ids'
        # instances should respond to their relationship ids setter method
        inst.should respond_to 'articles_ids='
        # build a sub-object
        article_one = inst.articles.create({ :name => 'Test' })
        # update the instance to contain this sub-object
        inst.update_attributes(:articles_ids => [article_one.id])
        # check it's in the list of ids
        inst.articles_ids.should == [article_one.id]
        # check we have one correct sub-object
        inst.articles.to_a.should == [article_one]
        # create another sub-object that's unrelated
        article_two = inst.articles.first.taxonomy.instances.create({ :name => 'Test 2' })
        # check we still only have one sub-object
        inst.articles.size.should == 1
        # load the sub object
        sub_object = inst.articles.first
        # check the sub-object responds to the parent relationship method
        sub_object.should respond_to 'categories'
        # check the sub-object has the instance in it's ids
        sub_object.categories_ids.should == [inst.id]
        # check the sub-object has the instance
        sub_object.categories.to_a.should == [inst]
        # update the instance to remove contain the sub-object
        inst.update_attributes(:articles_ids => [])
         # check we not longer have any ids
        inst.articles_ids.size.should == 0
        # check we have no sub-objects
        inst.articles.to_a.size == 0
        # reload the sub-object
        sub_object = sub_object.class.find(sub_object.id)
        # check the sub-object no longer has the instance in it's ids
        sub_object.categories_ids.size.should == 0
        # check the sub-object no longer has the instance
        sub_object.categories.to_a.size.should == 0
      end
    end
  end
  
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
    
    let(:instance) do
      @instance ||= taxonomy.instances.create({ :title => 'Test' })
    end
    
    it "should respond to liquidized methods" do
      inst = instance
      ['to_liquid', 'liquid_drop', 'liquid_drop_class'].each do |method|
        inst.should respond_to method
      end
      inst.liquid_drop_class.should == NestedDb::InstanceDrop
      inst.liquid_drop.class.should == NestedDb::InstanceDrop
      [NestedDb::InstanceDrop, Hash].should include inst.to_liquid.class
    end
  end

  describe "encrypted fields" do
    let(:taxonomy) do
      # wipe all taxonomies
      NestedDb::Taxonomy.delete_all
      # create the taxonomy
      @taxonomy = NestedDb::Taxonomy.create!({
        :name      => 'User',
        :reference => 'users'
      })
      # add a normal property
      @taxonomy.physical_properties.create!({
        :name      => 'password',
        :data_type => 'password'
      })
      # return
      @taxonomy
    end
    
    let(:instance) do
      instance = taxonomy.instances.build
      instance.write_attributes({ :password => 'Test', :password_confirmation => 'Test' })
      instance
    end
    
    it "should respond to the password getters/setters" do
      inst = taxonomy.instances.build
      inst.should respond_to 'password'
      inst.should respond_to 'password='
      inst.should respond_to 'password_confirmation'
      inst.should respond_to 'password_confirmation='
    end
    
    it "should set an instance variable to store the password on set" do
      inst = taxonomy.instances.build
      inst.password = 'hello'
      inst.password.should == 'hello'
      inst.instance_variable_get(:@password).should == 'hello'
    end
    
    it "should set an instance variable to store the password_confirmation on set" do
      inst = taxonomy.instances.build
      inst.password_confirmation = 'world'
      inst.password_confirmation.should == 'world'
      inst.instance_variable_get(:@password_confirmation).should == 'world'
    end
    
    it "should set the encrypted password and salt" do
      inst = instance
      inst.encrypted_password.should_not be_empty
      inst.password_salt.should_not be_empty
    end
    
    it "should return itself when successfully authenticating" do
      inst = instance
      inst.authenticate('password', 'Test').should == inst
    end
    
    it "should return nil when unsuccessfully authenticating" do
      inst = instance
      inst.authenticate('password', 'Test2').should be_nil
    end
  end

  describe "unique fields" do
    let(:taxonomy) do
      # wipe all taxonomies
      NestedDb::Taxonomy.delete_all
      # create the taxonomy
      @taxonomy = NestedDb::Taxonomy.create!({
        :name      => 'User',
        :reference => 'users'
      })
      # add a normal property
      @taxonomy.physical_properties.create!({
        :name      => 'username',
        :data_type => 'string',
        :unique    => true
      })
      # return
      @taxonomy
    end
    
    let(:instance) do
      instance = taxonomy.instances.build
      instance.write_attributes({ :username => 'one' })
      instance.save
      instance
    end
    
    it "should should disallow creation of new instances with the same unique value" do
      inst = instance
      new_inst = inst.taxonomy.instances.build
      new_inst.write_attributes({ :username => 'one' })
      new_inst.save.should == false
      new_inst.errors.keys.should include :username
    end
  end

  describe "callbacks" do
    let(:taxonomy) do
      # wipe all taxonomies
      NestedDb::Taxonomy.delete_all
      # create the taxonomy
      @taxonomy = NestedDb::Taxonomy.create!({
        :name      => 'User',
        :reference => 'users'
      })
      # add a normal property
      @taxonomy.physical_properties.create!({
        :name      => 'username',
        :data_type => 'string',
        :unique    => true,
        :required  => true
      })
      # add a normal property
      @taxonomy.callbacks.create!({
        :when         => 'after',
        :action       => 'create',
        :command      => 'webhook',
        :web_hook_url => 'http://example.com/'
      })
      # return
      @taxonomy
    end
    
    let(:instance) do
      instance = taxonomy.instances.build
      instance.write_attributes({ :username => 'one' })
      instance.save
      instance
    end
    
    it "should run the callbacks" do
      instance
    end
  end

end