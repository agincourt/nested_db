require 'spec_helper'

describe Liquid::FindTag do
  let(:liquid_context) do
    {
      "taxonomies.articles" => NestedDb::Liquid::TaxonomyDrop.new(Factory(:taxonomy)),
      "dynamic_column"      => 'price'
    }
  end

  it "should accept valid syntax" do
    lambda { Liquid::FindTag.new('find', "first articles as article", ['{% endfind %}']) }.should_not raise_error
    lambda { Liquid::FindTag.new('find', 'all articles as articles', ['{% endfind %}']) }.should_not raise_error
  end

  it "should deny invalid syntax" do
    lambda { Liquid::FindTag.new('find', '10 articles as articles', ['{% endfind %}']) }.should raise_error
    lambda { Liquid::FindTag.new('find', 'all articles as articles', []) }.should raise_error
  end

  it "should filter a taxonomy" do
    block = [
      "{% where 'price' > 5 %}",
      "{% order by dynamic_column desc %}",
      "{% limit to 5 %}"
    ]
    context = liquid_context
    tag = Liquid::FindTag.new('find', 'all articles as articles', block << "{% endfind %}")
    tag.render(context)
    tag.conditions.size.should == 3
    context.keys.should include 'articles'
    context['articles'].options[:limit].should == 5
    context['articles'].options[:sort].should == [[:price, :desc]]
    context['articles'].selector[:price].should == { "$gt" => 5 }
    context['articles'].class.should == Mongoid::Criteria
  end
end