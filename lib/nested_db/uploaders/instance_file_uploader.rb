# encoding: utf-8
require 'carrierwave'
require 'mini_magick'

class NestedDb::InstanceFileUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  
  process :resize_to_limit => [1000,1000]
  
  version :thumbnail do
    process :resize_to_fill => [95,70]
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
      model.taxonomy.scope_object.nested_db_bucket
    else
      super
    end
  end
  alias_method :s3_bucket, :fog_directory
  
  def s3_cnamed
    model.taxonomy.class.scoped? &&
    model.taxonomy.scope_object.respond_to?(:nested_db_bucket) &&
    model.taxonomy.scope_object.nested_db_bucket
  end
end
