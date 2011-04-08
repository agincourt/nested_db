class NestedDb::LiquidTestsController < NestedDb::ApplicationController
  def create
    @template = Liquid::Template.parse(params[:body])
    render :text => @template.render({
      'taxonomies' => TaxonomiesDrop.new
    })
  end
end
