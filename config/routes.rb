Rails.application.routes.draw do
  mount_avo
  root "home#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
