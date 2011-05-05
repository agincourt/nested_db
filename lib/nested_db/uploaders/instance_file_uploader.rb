# encoding: utf-8
require 'carrierwave'
require 'mini_magick'

class NestedDb::InstanceFileUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  
  attr_accessor :nested
  
  process :resize_to_limit => [1000,1000]
  
  version :thumbnail do
    process :resize_to_fill => [95,70]
  end
  
  def versions
    return @versions if defined?(@versions)
    # load the versions the original way
    super
    # if this isn't a nested uploader
    unless nested
      # if the model has it's own version
      if model.respond_to?(:versions)
        # merge them into the hash
        @versions.merge!(model.versions(mounted_as).to_a.inject({}) { |result,arr|
          version_uploader = self.class.new(model, mounted_as)
          version_uploader.class_eval arr[1] if arr[1]
          version_uploader.nested = true
          result.merge(arr[0].to_sym => version_uploader)
        })
      end
    end
    # return the versions
    @versions
  end
  
  def store_dir
    dir  = ''
    if defined?(Rails)
      dir += 'system/' unless Rails.env.production?
      dir += 'test/'   if Rails.env.test?
    else
      dir += 'test/'
    end
    dir += "files/#{model.taxonomy.reference}/#{ model.id }"
    dir.gsub(/\/$/, '')
  end
  
  def fog_directory
    s3_cnamed || super
  end
  alias_method :s3_bucket, :fog_directory
  
  def s3_cnamed
    model.taxonomy.class.scoped? &&
    model.taxonomy.scoped_object.respond_to?(:nested_db_bucket) &&
    model.taxonomy.scoped_object.nested_db_bucket.present? &&
    model.taxonomy.scoped_object.nested_db_bucket
  end
end
