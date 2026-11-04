Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  mount_avo
  root "home#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
