Rails.application.routes.draw do
  resources :orders
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  root "application#home"

  post 'orders/:id/capture', to: 'orders#capture'
end
