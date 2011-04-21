module NestedDb
  module Controllers
    module Taxonomies
      def self.included(base)
        base.class_eval do
          before_filter :load_taxonomy, :except => [ :index, :new, :create ]
        end
        base.send(:include, NestedDb::Controllers::Scoping)
        base.send(:include, NestedDb::Controllers::Routing)
        base.send(:include, NestedDb::Controllers::Views)
        base.send(:include, InstanceMethods)
      end
      
      module InstanceMethods
        def index
          @taxonomies = taxonomy_scope.order_by(:name.asc)
        end
        
        def new
          @taxonomy = taxonomy_scope.new
          @taxonomy.physical_properties.build
        end
        
        def edit; end
        def delete; end
        
        def create
          @taxonomy = taxonomy_scope.new(params[:nested_db_taxonomy])
          if @taxonomy.class.scoped?
            @taxonomy.send("#{@taxonomy.class.scoped_to.to_s}=", scope_parent)
          end
          
          case params[:activity]
          when 'add_physical_property'
            @taxonomy.physical_properties.build(:index => (@taxonomy.physical_properties.try(:last).try(:index) || -1) + 1)
          else
            @taxonomy.save
          end
          
          respond_with(@taxonomy) do |wants|
            wants.html { @taxonomy.persisted? ? redirect_to({ :action => :index }, :notice => 'Taxonomy created.') : render(:new) }
          end
        end
        
        def update
          @taxonomy.write_attributes(params[:nested_db_taxonomy])
          
          case params[:activity]
          when 'add_physical_property'
            @taxonomy.physical_properties.build(:index => (@taxonomy.physical_properties.try(:last).try(:index) || -1) + 1)
          else
            @saved = @taxonomy.save
          end
          
          respond_with(@taxonomy) do |wants|
            wants.html { @saved && @taxonomy.errors.empty? ? redirect_to({ :action => :show, :id => @taxonomy.id }, :notice => 'Taxonomy updated.') : render(:edit) }
          end
        end
        
        def destroy
          @taxonomy.try(:destroy)
          redirect_to({ :action => :index }, :notice => 'Taxonomy deleted.')
        end
        
        protected
        def load_taxonomy
          @taxonomy = taxonomy_scope.find(params[:id])
        rescue ActiveRecord::RecordNotFound => e
          Rails.logger.debug "#{e.class.name.to_s} => #{e.message}"
          redirect_to({ :action => :index }, :notice => "Taxonomy not found.")
        end
      end
    end
  end
end