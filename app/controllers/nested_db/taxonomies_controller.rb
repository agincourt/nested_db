module NestedDb
  module TaxonomiesController
    def self.included(base)
      base.send(:include, Controllers::Scoping)
      base.send(:include, Controllers::Routing)
      base.send(:include, InstanceMethods)
      base.class_eval do
        before_filter :load_taxonomy, :except => [ :index, :new, :create ]
      end
    end

    module InstanceMethods
      def index
        @taxonomies = taxonomy_scope.order_by(:name.asc)
      end

      def show
        @instances = @taxonomy.instances.paginate(:per_page => 20, :page => params[:page])
          # order_by(
          #   params[:order] && params[:order][:column] && @taxonomy.has_property?(params[:order][:column]) ?
          #   params[:order][:column].to_sym.send('asc' == params[:order][:direction] ? :asc : :desc) :
          #   :created_at.desc).
          # paginate(:per_page => params[:per_page] || ::Instance.per_page, :page => params[:page])
      end

      def new
        @taxonomy = taxonomy_scope.new
        @taxonomy.virtual_properties.build
        @taxonomy.physical_properties.build
        @taxonomy.instance_callbacks.build
        @taxonomy.physical_properties.each { |pp| pp.image_versions.build }
      end

      def edit
        @taxonomy.virtual_properties.build  unless @taxonomy.virtual_properties.size > 0
        @taxonomy.physical_properties.build unless @taxonomy.physical_properties.size > 0
        @taxonomy.instance_callbacks.build unless @taxonomy.instance_callbacks.size > 0
        @taxonomy.physical_properties.each { |pp| pp.image_versions.build }
      end

      def create
        @taxonomy = taxonomy_scope.new(params[:taxonomy])
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
          wants.html { @taxonomy.persisted? ? redirect_to({ :action => :show, :id => @taxonomy.id }, :notice => 'Taxonomy created.') : render(:new) }
        end
      end

      def update
        @taxonomy.write_attributes(params[:taxonomy])

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

      def delete
        destroy && return unless 'GET' == request.method
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
        loading_taxonomy_failed
        return false
      end

      def loading_taxonomy_failed
        redirect_to({ :action => :index }, :notice => "Taxonomy not found.")
      end
    end
  end
end