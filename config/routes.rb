Rails.application.routes.draw do
  get 'samples/group'
  post 'samples/group_save'

  get 'import/experiment'
  get 'import/importlog'

  get 'filter/edit'
  post 'filter/edit'
  get 'filter/list'
  get 'filter/get_list'
  get 'filter/list_oxi'
  get 'filter/get_list_oxi'
  get 'filter/statistics'

  get 'features' => 'features#index', as: :feature_index
  get 'features/show/:feature' => 'features#show', as: :feature, feature: :number
  get 'features/load_features'
  get 'features/plot_2d'
  get 'features/oxichain'
  get 'features/oxichain_find'
  get 'features/oxichain_export'


  resources :lipids do
    collection do
      post 'search', as: :search, action: :search
    end
  end

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'
  root :to => 'home#index'
  match "clear_sessions" => 'home#clear_sessions', :via => :get
  match "download_slim" => 'home#download_slim', :via => :get

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
