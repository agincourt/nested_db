module NestedDb
  module Proxies
    class InstanceProxy < Proxy
      # load our relation
      def relation!
        super
        # load the instances by taxonomy
        @instances = (options[:taxonomy] || source).instance_class.scoped
      end

      # load our taxonomy for the relation
      def taxonomy
        # load the instance's taxonomy, then
        # load the taxonomy from the specified property
        source.taxonomy.properties[destination].taxonomy
      end

      def synchronise(ids)
        remove_from_remote_habtm_associations(ids)
      end

      # remove this object's id from all remote objects (used in deletion)
      def remove_from_all_remote_habtm_associations
        remove_from_remote_habtm_associations
      end

      private
      # remove this object's id from objects no longer in
      # this object's list of HABTM ids
      def remove_from_remote_habtm_associations(ids = nil)
        # find all the instances which contain this id
        criteria = taxonomy.instances.
          where(foreign_key => id).
          where(foreign_key.exists => true)
        # limit to the ones that shouldn't have this id
        criteria = criteria.not_in(:_id => ids) if ids
        # update them to remove it
        criteria.klass.collection.update(
          criteria.selector,
          { '$pull' => { foreign_key => source.id } },
          :multi => true,
          :safe => Mongoid.persist_in_safe_mode
        )
      end

      # adds this object's id to any new additions to the HABTM association
      def add_to_new_remote_habtm_associations(ids)
        # find all the instances which should contain this ID
        criteria = proxy.taxonomy.instances.
          any_in(:_id => ids)
        # update them to add it
        criteria.klass.collection.update(
          criteria.selector,
          { '$addToSet' => { foreign_key => source.id } },
          :multi => true,
          :safe => Mongoid.persist_in_safe_mode
        )
      end
    end
  end
end