class NestedDb::ApplicationController < ApplicationController
  respond_to :html, :xml, :json

  protected
  def taxonomy_scope
    Taxonomy
  end
end
