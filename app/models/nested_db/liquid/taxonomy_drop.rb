require 'digest/md5'

module NestedDb
  module Liquid
    class TaxonomyDrop < ::Liquid::Drop
      attr_accessor :taxonomy

      def initialize(taxonomy)
        self.taxonomy = taxonomy
      end

      def name
        taxonomy.name
      end

      def cache_key
        Digest::MD5.hexdigest("#{taxonomy.id}-#{taxonomy.updated_at}")
      end

      def all
        taxonomy.instances.limit(100)
      end

      def count
        taxonomy.instances.count
      end
    end
  end
end