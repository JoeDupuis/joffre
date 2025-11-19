Rails.application.routes.draw do
  root "dashboard#index"

  resource :session
  resource :registration, only: %i[new create]
  resources :passwords, param: :token
  resources :games, only: [ :index, :new, :create, :show, :update, :destroy ] do
    scope module: :games do
      resources :bids, only: [ :create ]
      resources :plays, only: [ :create ]
    end
  end

  namespace :games do
    resources :players
  end
  resources :friendships, only: [ :index, :new, :create, :update, :destroy ]

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  if Rails.env.development? || Rails.env.test?
    post "dev/switch_user" => "dev#switch_user", as: :dev_switch_user
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
