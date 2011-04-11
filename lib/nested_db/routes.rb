module ActionDispatch::Routing
  class Mapper
    def nested_db(options = {})
      resources :taxonomies, :controller => options[:taxonomies_controller] || 'taxonomies' do
        get :delete, :on => :member
        resources :instances, :controller => options[:instances_controller] || 'taxonomies/instances' do
          get :delete, :on => :member
        end
      end
    end
  end
end