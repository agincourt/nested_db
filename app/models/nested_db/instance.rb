class NestedDb::Instance
  include Mongoid::Document
  include NestedDb::Models::Instance
end