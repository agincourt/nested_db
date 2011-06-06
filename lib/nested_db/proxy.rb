module NestedDb
  class Proxy
    # class methods
    class << self
      def from(source)
        case source
        when ::Taxonomy
          Proxies::TaxonomyProxy.new(source)
        when ::Instance
          Proxies::InstanceProxy.new(source)
        else
          raise StandardError, "Unrecognised class use in proxy: #{source.class.name}"
        end
      end
    end

    attr_accessor :source, :destination, :type
    delegate      :find, :all, :first, :to => 'relation'

    # instance methods
    def initialize(source)
      self.source = source
    end

    # sets the destination field
    def to(destination)
      self.destination = destination
      self
    end

    # sets the type field
    def using(type)
      self.type = type
      self
    end

    # builds a new object
    def build(params = {})
      relation.build(params.merge(:taxonomy => taxonomy))
    end

    # creates a new object
    def create(params = {})
      object = build(params)
      object.save
      object
    end

    # creates a new object, and throws an error if failed
    def create!(params = {})
      object = build(params)
      object.save!
      object
    end

    # load our relation and memoize
    def relation
      @instances ||= relation!
      puts @instances.inspect
      @instances
    end
    alias_method :getter, :relation

    # load our relation
    def relation!
      # load the instances by taxonomy
      @instances = taxonomy.instance_class.scoped
    end

    # load our taxonomy for the relation
    def taxonomy
      source
    end

    # is this relation a HABTM?
    def habtm?;      'has_and_belongs_to_many' == type; end
    def many?;       'has_many' == type; end
    def belongs_to?; 'belongs_to' == type; end
  end
end