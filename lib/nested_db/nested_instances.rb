module NestedDb
  class NestedInstances
    attr_accessor :parent,
                  :taxonomy,
                  :objects,
                  :destroy_ids,
                  :errors,
                  :reverse_association
    
    def initialize(parent, options = {})
      # setup an array to hold the objects
      self.objects ||= []
      # setup an array to hold ids of those which should be deleted
      self.destroy_ids ||= []
      # set the taxonomy
      self.taxonomy = options[:taxonomy]
      # set the parent
      self.parent = parent
      # set the reverse association
      self.reverse_association = options[:inverse_of]
      
      # loop through each attribute set to setup each object
      (options[:attributes] || {}).each do |i,attrs|
        attrs.symbolize_keys!
        # pull out the ID (if present)
        existing_id = attrs.delete(:id)
        # if we have an ID
        if existing_id
          # find the existing object
          obj = taxonomy.instances.find(existing_id)
          # set the taxonomy
          obj.taxonomy = taxonomy
          # call extend
          obj.extend_based_on_taxonomy
          # set parent
          obj.send(reverse_association, parent)
          # update it with new attributes
          obj.write_attributes(attrs)
          # if this is set to destroy
          self.destroy_ids << existing_id if attrs.has_key(:destroy)
        # don't setup a new field if it's set to be destroyed
        elsif !attrs.has_key(:destroy)
          # create the new object
          obj = taxonomy.instances.build
          # call extend
          obj.extend_based_on_taxonomy
          # set parent
          obj.send(reverse_association, parent)
          # update it with new attributes
          obj.write_attributes(attrs)
        end
        # add this object to the set
        self.objects << obj if obj
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
      valid? || (errors.length == 1 && errors.has_key?(reverse_association))
    end
    
    # save each of the objects, or delete where required
    def save
      objects.each do |object|
        # if this object has been saved, and it's marked for deletion
        if object.persisted? && destroy_ids.include?(object.id)
          # delete it
          object.destroy
        else
          # update the parent
          obj.send(reverse_association, parent)
          # save the object
          obj.save
        end
      end
    end
    
  end
end