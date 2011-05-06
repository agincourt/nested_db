# encoding: utf-8
require 'carrierwave'
require 'mini_magick'

class NestedDb::InstanceFileUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  
  # add a local store for version names
  attr_accessor :version_names
  
  # default version_names to an array
  def version_names
    @version_names ||= []
  end
  
  # override the version_name method to factor in instance version_names
  def version_name
    if version_names.empty?
      super
    else
      Array(super).push(version_names).join('_').to_sym
    end
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
