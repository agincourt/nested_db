module NestedDb
  class TaxonomiesController < ApplicationController
    include Controllers::Scoping
    include Controllers::Routing

    before_filter :load_taxonomy
    before_filter :load_instance, :except => [ :index, :new, :create ]

    def index
      @instances = @taxonomy.instances

      respond_with(@instances) do |wants|
        wants.html { redirect_to(taxonomy_relative_to_instance_url) }
      end
    end

    def new
      @instance = @taxonomy.instances.build
      @taxonomy.physical_properties.select { |pp| 'has_many' == pp.data_type }.each { |pp|
        @instance.send(pp.name).build if @instance.send(pp.name).size == 0
      }
    end

    def edit
      @taxonomy.physical_properties.select { |pp| 'has_many' == pp.data_type }.each { |pp|
        @instance.send(pp.name).build if @instance.send(pp.name).size == 0
      }
    end

    def create
      @instance = @taxonomy.instances.create(params[:instance])

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
      @instance.update_attributes(params[:instance])

      respond_with(@instance) do |wants|
        wants.html { @instance.errors.empty? ? redirect_to(taxonomy_relative_to_instance_url) : render(:edit) }
      end
    end

    def delete
      destroy && return unless 'GET' == request.method
    end

    def destroy
      @instance.try(:destroy)
      redirect_to(taxonomy_relative_to_instance_url, :notice => "#{@taxonomy.name.titleize} deleted!")
    end

    protected
    def load_taxonomy
      @taxonomy = taxonomy_scope.find(params[:taxonomy_id])
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.debug "#{e.class.name.to_s} => #{e.message}"
      loading_taxonomy_failed
    end

    def load_instance
      @instance = @taxonomy.instances.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.debug "#{e.class.name.to_s} => #{e.message}"
      loading_instance_failed
    end

    def not_found
      head :not_found
    end
    alias_method :loading_taxonomy_failed, :not_found
    alias_method :loading_instance_failed, :not_found
  end
end