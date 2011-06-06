module NestedDb
  module Proxies
    class TaxonomyProxy < Proxy
      def type
        'has_many'
      end
    end
  end
end