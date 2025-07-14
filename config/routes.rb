Rails.application.routes.draw do
  
  namespace :webhooks do
    post 'lstep', to: 'lstep#create'
  end
  
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    passwords: 'users/passwords',
    confirmations: 'users/confirmations',
    unlocks: 'users/unlocks'
  }
  

  root "home#index"
  
  get 'terms', to: 'home#terms', as: :terms
  get 'privacy', to: 'home#privacy', as: :privacy
  get 'law', to: 'home#law', as: :law

  # config/routes.rb
  resources :inquiries, only: [:new, :create]
  
  namespace :admin do
    resources :products, only: [:index, :edit, :update]
    root to: 'dashboard#index'  # /admin をダッシュボードに
    get "users/show"
    resources :users, only: [:index, :show]
    resources :inquiries, only: [:index, :show] do
      resources :answers, only: [:new, :create, :edit, :update, :destroy]
    end
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
  
  # config/routes.rb
  # https 
    constraints(host: 'msworks.tokyo') do
      get '(*path)', to: redirect { |params, req|
        "https://www.msworks.tokyo/#{params[:path]}"
      }
    end

  
end
