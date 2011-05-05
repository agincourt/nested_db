class NestedDb::Instance
  include NestedDb::Models::Instance
  
  def versions
    {
      'square' => 'process :resize_to_fill => [200,200]'
    }
  end
end