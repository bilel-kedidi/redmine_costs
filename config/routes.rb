# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :cost_entries,  :controller => 'cost_entry'  do
  get 'report', :on => :collection
end
resources :issues do
  resources :cost_entries,  :controller => 'cost_entry'  do
    get 'report', :on => :collection
  end
end
resources :projects do
  post 'project_enumerations/update_cost_entry', to: "project_enumerations#update_cost_entry"
  delete 'project_enumerations/destroy_cost_entry', to: "project_enumerations#destroy_cost_entry"
  resources :cost_entries,  :controller => 'cost_entry'  do
    get 'report', :on => :collection
  end

  post 'project_cost/set_costs', controller: :project_cost, action: :set_costs
  post 'project_cost/set_costs_items', controller: :project_cost, action: :set_costs_items
end