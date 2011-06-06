module NestedDb
  class Instance
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mongoid::Paranoia
    include Mongoid::MultiParameterAttributes
    include NestedDb::Models::CallbackProcessing
    include NestedDb::DynamicAttributes
    include Liquidizable

    attr_accessor :ignore_errors

    # pagination
    cattr_reader :per_page
    @@per_page = 20

    # fields
    field :auto_incremented_id, :type => Integer

    # associations
    belongs_to :taxonomy

    # validation
    validates_presence_of :taxonomy

    # callbacks
    after_validation :generate_auto_incremented_id
    after_validation :process_rich_text
    after_validation :process_virtual_properties
    after_save       :touch_taxonomy
    after_destroy    :touch_taxonomy

    # class methods
    class << self
      def search_on(property, options = {})
        case options[:using]
        when :match
          where(property.to_sym.matches => options[:for])
        else
          where(property.to_sym => options[:for])
        end
      end

      def image_variation(input, variation = nil)
        input ||= ''
        input = input.url if input.kind_of?(CarrierWave::Uploader::Base)
        input = input.gsub(/^(.*)\/(.*?)$/, "\\1/#{variation.to_s}_\\2") if variation
        input
      end
    end

    # instance methods
    # used by to_json to output user-viewable data
    def serializable_hash
      super.delete_if { |k,v|
        k.to_s =~ /^encrypted|salt$/
      }
    end

    # returns a class which will be used to
    # represent individual instances in liquid
    def liquid_drop_class
      NestedDb::Liquid::InstanceDrop
    end

    def ignore_errors_on(properties)
      self.ignore_errors ||= []
      self.ignore_errors +=  Array(properties)
    end

    def valid?(force = nil)
      self.ignore_errors ||= []
      self.ignore_errors.map!(&:to_sym)

      super || self.errors.delete_if { |k,v| ignore_errors.include?(k.to_sym) }.size == 0
    end

    def versions(mounted_as)
      # if the taxonomy doesn't have this property, return blank hash
      return {} unless taxonomy.has_property?(mounted_as)
      # load the property
      property = taxonomy.properties[mounted_as.to_s]
      # map the versions into a hash
      (property.try(:image_versions) || []).inject({}) { |result,iv|
        result.merge(iv.name => iv.processes)
      }
    end

    private
    def generate_auto_incremented_id
      self.auto_incremented_id = (taxonomy.instances.order_by([[:auto_incremented_id, :desc]]).first.try(:auto_incremented_id) || 0) + 1 if new_record?
    end

    # process the rich text fields into HTML
    def process_rich_text
      taxonomy.physical_properties.where(:data_type => 'rich_text').each do |pp|
        if self.send(pp.name).present?
          write_attribute("#{pp.name}_rich_text_processed", RedCloth.new(self.send(pp.name)).to_html)
        end
      end
    end

    # process each virtual attribute
    def process_virtual_properties
      # loop through each attribute
      taxonomy.virtual_properties.each do |vp|
        # if this is a new instance
        # or the attribute can be set on update
        unless persisted? && vp.only_create?
          # get the value and set it
          write_attribute(vp.name, vp.value(self))
        end
      end
    end

    # updates the taxonomy's updated_at time
    def touch_taxonomy
      taxonomy.save
    end
  end
end