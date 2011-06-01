require 'digest/md5'

FactoryGirl.define do
  sequence :email do |n|
    "person#{random_hash}@example#{n}.com"
  end
  
  sequence :name do |n|
    "david#{n} smith#{random_hash[0..4]}"
  end
  
  sequence :permalink do |n|
    "something-#{n}-#{random_hash[0..8]}"
  end
  
  sequence :number do |n|
    n
  end
  
  sequence :ip do |n|
    "#{rand(255)}.#{rand(255)}.#{rand(255)}.#{rand(255)}"
  end
end

def random_hash
  Digest::MD5.hexdigest("#{Time.now}_#{rand(1000)}")
end