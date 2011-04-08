module NestedDb
  module InstancesController
    def self.included(base)
      base.class_eval do
        before_filter :load_taxonomy
        before_filter :load_instance, :except => [ :index, :new, :create ]
      end
      
      base.send(:include, InstanceMethods)
    end
    
    module InstanceMethods
      def new
        @instance = @taxonomy.instances.build
      end
      
      def create
        respond_with(@instance = @taxonomy.instances.create(params[:instance])) do |wants|
          wants.html {
            if @instance.persisted?
              redirect_to(@taxonomy, :notice => "#{@taxonomy.name.titleize} created!")
            else
              render(:new)
            end
          }
        end
      end
      
      def update
        @instance.update_attributes(params[:instance])
        
        respond_with(@instance) do |wants|
          wants.html { @instance.errors.empty? ? redirect_to(@taxonomy) : render(:edit) }
        end
      end
      
      def destroy
        @instance.try(:destroy)
        redirect_to(@taxonomy)
      end
      
      protected
      def load_taxonomy
        @taxonomy = (self.respond_to?(:taxonomy_scope) ? taxonomy_scope : Taxonomy).find(params[:taxonomy_id])
      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.debug "#{e.class.name.to_s} => #{e.message}"
        head :not_found
      end
  
      def load_instance
        @instance = @taxonomy.instances.find(params[:id])
      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.debug "#{e.class.name.to_s} => #{e.message}"
        head :not_found
      end
    end
  end
end