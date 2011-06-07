module ActionDispatch::Routing
  class Mapper
    def nested_db(options = {})
      resources :taxonomies, :controller => options[:taxonomies_controller] || 'taxonomies' do
        match :delete, :on => :member, :via => [:get, :delete]
        resources :instances, :controller => options[:instances_controller] || 'instances' do
          match :delete, :on => :member, :via => [:get, :delete]
        end
      end
    end
  end
end