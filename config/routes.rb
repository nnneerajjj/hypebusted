Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :posts, only: :show, param: :slug
  mount_avo
  root "home#index"

  get "sitemap.xml" => "sitemaps#show", defaults: { format: :xml }
  get "up" => "rails/health#show", as: :rails_health_check
end
