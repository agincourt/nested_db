class NestedDb::InstanceImageUploader < NestedDb::InstanceFileUploader
  process :resize_to_limit => [1000,1000]
  
  version :thumbnail do
    process :resize_to_fill => [95,70]
  end
  
  def versions
    return @versions if defined?(@versions)
    # load the versions the original way
    super
    # if this isn't a nested uploader
    if version_names.empty?
      # if the model has it's own version
      if model.respond_to?(:versions)
        # merge them into the hash
        @versions.merge!(model.versions(mounted_as).to_a.inject({}) { |result,arr|
          version_uploader = NestedDb::InstanceVersionUploader.new(model, mounted_as)
          version_uploader.processors = arr[1] if arr[1]
          version_uploader.version_names.push(version_names) unless version_names.empty?
          version_uploader.version_names.push(arr[0].to_sym)
          result.merge(arr[0].to_sym => version_uploader)
        })
      end
    end
    # return the versions
    @versions
  end
  
  # limit to images
  def extension_white_list
     %w(jpg jpeg gif png)
  end
end