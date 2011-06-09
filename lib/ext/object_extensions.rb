# module NestedDb
#   module ObjectExtensions
#     def self.included(base)
#       base.extend ClassMethods
#     end
#     
#     module ClassMethods
#       def const_missing(name)
#         if name =~ NestedDb::Instances.regex
#           puts "const missing: #{name}"
#           NestedDb::Instances.find_or_create($1)
#         else
#           super(name)
#         end
#       end
#     end
#   end
# end
# 
# Object.send(:include, NestedDb::ObjectExtensions)