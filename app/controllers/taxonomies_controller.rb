class NestedDb::TaxonomiesController < NestedDb::ApplicationController
  before_filter :load_taxonomy, :except => [ :index, :new, :create ]
  
  def index
    @taxonomies = taxonomy_scope.order_by(:name.asc)
  end
  
  def new
    @taxonomy = taxonomy_scope.new
    @taxonomy.physical_properties.build
  end
  
  def create
    @taxonomy = taxonomy_scope.new(params[:taxonomy])
    
    case params[:activity]
    when 'add_physical_property'
      @taxonomy.physical_properties.build(:index => (@taxonomy.physical_properties.try(:last).try(:index) || -1) + 1)
    else
      @taxonomy.save
    end
    
    respond_with(@taxonomy) do |wants|
      wants.html { @taxonomy.persisted? ? redirect_to(:taxonomies) : render(:new) }
    end
  end
  
  def update
    @taxonomy.write_attributes(params[:taxonomy])
    
    case params[:activity]
    when 'add_physical_property'
      @taxonomy.physical_properties.build
    else
      @saved = @taxonomy.save
    end
    
    respond_with(@taxonomy) do |wants|
      wants.html { @saved && @taxonomy.errors.empty? ? redirect_to(:taxonomies) : render(:edit) }
    end
  end
  
  def destroy
    @taxonomy.try(:destroy)
    redirect_to(:taxonomies)
  end
  
  protected
  def load_taxonomy
    @taxonomy = taxonomy_scope.find(params[:id])
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.debug "#{e.class.name.to_s} => #{e.message}"
    redirect_to({ :action => :index }, :notice => "Taxonomy not found.")
  end
end
