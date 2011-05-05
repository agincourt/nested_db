class NestedDb::Instance
  include NestedDb::Models::Instance
  
  def versions(mounted_as)
    {
      'square'        => 'process :resize_to_fill => [200,200]',
      mounted_as.to_s => 'process :resize_to_fill => [500,240]'
    }
  end
end