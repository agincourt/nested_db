class TaxonomiesController < ApplicationController
  include NestedDb::TaxonomiesController

  # You can override the following methods to adjust behaviour:
  # def loading_taxonomy_failed; end
  # => what happens when taxonomy cannot be found
end