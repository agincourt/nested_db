class NestedDb::InstanceVersionUploader < NestedDb::InstanceImageUploader
  attr_accessor :processors
  
  def process!(new_file=nil)
    if enable_processing
      (processors || []).each do |method, args, condition|
        next if condition && !self.send(condition, new_file)
        self.send(method, *args)
      end
    end
  end
end