module NestedDb
  module Controllers
    module Instances
      def self.included(base)
        base.class_eval do
          before_filter :load_taxonomy
          before_filter :load_instance, :except => [ :index, :new, :create ]
        end
        
        base.send(:include, NestedDb::Controllers::Scoping)
        base.send(:include, NestedDb::Controllers::Routing)
        base.send(:include, NestedDb::Controllers::Views)
        base.extend ClassMethods
        base.send(:include, InstanceMethods)
      end
      
      module ClassMethods
        private
        def default_view_path
          'taxonomies/instances'
        end
      end
      
      module InstanceMethods
        def new
          @instance = @taxonomy.instances.build
        end
        
        def edit; end
        
        def create
          @instance            = @taxonomy.instances.build
          @instance.attributes = params[:nested_db_instance]
          @instance.save
          
          respond_with(@instance) do |wants|
            wants.html {
              if @instance.persisted?
                redirect_to(taxonomy_relative_to_instance_url, :notice => "#{@taxonomy.name.titleize} created!")
              else
                render(:new)
              end
            }
          end
        end
        
        def update
          @instance.update_attributes(params[:nested_db_instance])
        
          respond_with(@instance) do |wants|
            wants.html { @instance.errors.empty? ? redirect_to(taxonomy_relative_to_instance_url) : render(:edit) }
          end
        end
        
        def delete
          destroy && return if 'DELETE' == request.method
        end
        
        def destroy
          @instance.try(:destroy)
          redirect_to(taxonomy_relative_to_instance_url)
        end
        
        protected
        def load_taxonomy
          @taxonomy = taxonomy_scope.find(params[:taxonomy_id])
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
end