FactoryGirl.define do
  factory :taxonomy do
    name        { Factory(:permalink) }
    reference   { Factory(:permalink) }
    after_create do |taxonomy|
      taxonomy.physical_properties.create!({ :name => 'title', :data_type => 'string', :required => true })
      taxonomy.physical_properties.create!({ :name => 'price', :data_type => 'money', :required => true })
      taxonomy.instances.create!(Factory.attributes_for(:taxonomy_instance))
    end
  end

  factory :taxonomy_instance, :class => 'Instance' do
    title 'Test'
    price 12.34
  end

  sequence :instance do
    Factory(:taxonomy).instances.first
  end
end