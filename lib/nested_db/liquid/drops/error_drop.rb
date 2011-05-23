module NestedDb
  class ErrorDrop < ::Liquid::Drop
    attr_accessor :field, :message
    
    def initialize(field, message)
      self.field   = field
      self.message = message
    end
    
    def full_message
      'base' == field ? message : "#{field} #{message}"
    end
  end
end