module NestedDb
  class NestedInstances
    attr_accessor :parent,
                  :taxonomy,
                  :objects,
                  :destroy_ids,
                  :errors,
                  :reverse_association,
                  :association
    
    def initialize(parent, options = {})
      # setup an array to hold the objects
      self.objects ||= []
      # setup an array to hold ids of those which should be deleted
      self.destroy_ids ||= []
      # set the parent
      self.parent = parent
      # set the taxonomy
      self.taxonomy = options[:taxonomy]
      # set the associations
      self.reverse_association = options[:inverse_of]
      self.association         = options[:association_name]
      
      # loop through each attribute set to setup each object
      (options[:attributes] || {}).each do |i,attrs|
        attrs.symbolize_keys! unless attrs.kind_of?(ActiveSupport::HashWithIndifferentAccess)
        # pull out the ID (if present)
        existing_id = attrs.delete(:id)
        # if all attributes are blank, skip
        next if attrs.all? { |_, value| value.blank? }
        # if we have an ID
        if existing_id
          # find the existing object
          obj = parent.send(association).select { |o| existing_id.to_s == o.id.to_s }.first
          # ensure we have the object
          next unless obj
          # set the taxonomy
          obj.taxonomy = taxonomy
          # call extend
          obj.extend_based_on_taxonomy
          # set parent
          obj.send(reverse_association, parent)
          # if this is set to destroy
          self.destroy_ids << obj.id if attrs.delete(:_destroy)
        # don't setup a new field if it's set to be destroyed
        elsif !attrs.delete(:_destroy)
          # create the new object
          obj = parent.send(association).build
          # call extend
          obj.extend_based_on_taxonomy
          # ignore errors on association
          obj.ignore_errors_on(reverse_association)
          # update the parent
          obj.send("#{reverse_association}=", parent) if parent.persisted?
        end
        
        # if we have an object
        if obj
          # update the attributes
          attrs.each { |k,v| obj.send("#{k.to_s}=", v) }
          # add this object to the set
          self.objects << obj
        end
      end
    end
    
    def valid?
      # setup hash to store errors
      self.errors = {}
      # validate each object and
      # merge in any errors
      objects.each do |object|
        # if it's invalid
        unless object.valid?
          # loop through errors and append
          object.errors.each do |key,value|
            self.errors.merge!(key => value)
          end
        end
      end
      # 
    end
    
    # allow one error, if it's on the association
    def valid_as_nested?
      valid? # || (errors.length == 1 && errors.has_key?(reverse_association))
    end
    
    # save each of the objects, or delete where required
    def save
      objects.each do |object|
        # if this object has been saved, and it's marked for deletion
        if destroy_ids.include?(object.id)
          # delete it
          object.destroy
        else
          # update the parent
          object.send("#{reverse_association}=", parent)
          # save the object
          object.save
        end
      end
    end
    
  end
end