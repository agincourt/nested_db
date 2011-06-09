require "spec_helper"

describe NestedDb::InstanceCallback do
  describe "validation" do
    let(:taxonomy) do
      return @taxonomy if defined?(@taxonomy)
      # wipe all taxonomies
      NestedDb::Taxonomy.delete_all
      # create the taxonomy
      @taxonomy = NestedDb::Taxonomy.create!({
        :name      => 'Category',
        :reference => 'categories'
      })
    end
    
    it "should have the fields of it's commands applied" do
      taxonomy.instance_callbacks.build.fields.keys.should include 'web_hook_url'
    end
    
    it "should require proper input when specifying callbacks" do
      # add a normal property
      callback = taxonomy.instance_callbacks.create({
        :when    => 'after',
        :action  => 'create',
        :command => 'webhook'
      })
      # check callback is invalid
      callback.persisted?.should_not be_true
      callback.errors.keys.should include :web_hook_url
    end
  end
end