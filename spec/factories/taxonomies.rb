FactoryGirl.define do
  factory :taxonomy do
    name        { Factory(:permalink) }
    reference   { Factory(:permalink) }
    after_create do |taxonomy|
      taxonomy.physical_properties.create!({ :name => 'title', :data_type => 'string', :required => true })
      taxonomy.physical_properties.create!({ :name => 'price', :data_type => 'money', :required => true })
    end
  end

  factory :instance do
    taxonomy { Factory(:taxonomy) }
    title    'Test'
    price    12.34
  end
end