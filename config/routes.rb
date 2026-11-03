Rails.application.routes.draw do
  resources :books, param: :serial_number, only: %i[ index show create destroy ]
  resources :readers, param: :card_number, only: %i[ index show create update destroy ]
  resources :borrowings, only: %i[ create update ]

  get "up" => "rails/health#show", as: :rails_health_check
end
