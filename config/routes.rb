Rails.application.routes.draw do
  # Webhook
  namespace :webhooks do
    post 'lstep', to: 'lstep#create'
    post 'lstep/purchase', to: 'lstep#purchase'
  end

  # Devise
  devise_for :users, controllers: {
    sessions:      'users/sessions',
    registrations: 'users/registrations',
    passwords:     'users/passwords',
    confirmations: 'users/confirmations',
    unlocks:       'users/unlocks'
  }

  # トップページと各種ページ
  root "home#index"
  get 'terms',   to: 'home#terms',   as: :terms
  get 'privacy', to: 'home#privacy', as: :privacy
  get 'law',     to: 'home#law',     as: :law

  # お問い合わせ
  resources :inquiries, only: [:new, :create]

  # 管理者画面
  namespace :admin do
    root to: 'dashboard#index'  # /admin → ダッシュボード
    resources :sales, only: [:index]
    resources :products, only: [:index, :edit, :update]

    resources :users, only: [:index, :show]
    resources :inquiries, only: [:index, :show] do
      resources :answers, only: [:new, :create, :edit, :update, :destroy]
    end
  end

  # 一般ユーザー用マイページ
  get 'mypage', to: 'users#mypage', as: :mypage
  resources :users, only: [:show]  # /users/:id → 下位ユーザー詳細
  resources :sales, only: [:index]

  # ヘルスチェック
  get "up", to: "rails/health#show", as: :rails_health_check

  # HTTPS強制リダイレクト（www.msworks.tokyo）
  constraints(host: 'msworks.tokyo') do
    get '(*path)', to: redirect { |params, req|
      "https://www.msworks.tokyo/#{params[:path]}"
    }
  end
end
