# encoding: utf-8
require 'carrierwave'
require 'mini_magick'

class NestedDb::InstanceFileUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  
  process :resize_to_limit => [1000,1000]
  
  version :thumbnail do
    process :resize_to_fill => [95,70]
  end
  
  def versions
    return @versions if defined?(@versions)
    # load the versions the original way
    super
    # if the model has it's own version
    if model.respond_to?(:versions)
      # merge them into the hash
      @versions.merge!(model.versions(mounted_as).to_a.inject({}) { |hash,arr|
        version_uploader = self.class.new(model, mounted_as)
        version_uploader.class_eval arr[1] if arr[1]
        hash.merge(arr[0].to_sym => version_uploader)
      })
    end
    # return the versions
    @versions
  end
  
  def store_dir
    dir  = ''
    dir += 'system/' unless Rails.env.production?
    dir += 'test/'   if Rails.env.test?
    dir += "files/#{model.taxonomy.reference}/#{ model.id }"
    dir.gsub(/\/$/, '')
  end
  
  def fog_directory
    if s3_cnamed
      model.taxonomy.scoped_object.nested_db_bucket
    else
      super
    end
  end
  alias_method :s3_bucket, :fog_directory
  
  def s3_cnamed
    model.taxonomy.class.scoped? &&
    model.taxonomy.scoped_object.respond_to?(:nested_db_bucket) &&
    model.taxonomy.scoped_object.nested_db_bucket
  end
  
  def method_missing(method, *args)
    if versions.has_key?(method.to_s)
      versions[method.to_s]
    else
      super
    end
  end
end
