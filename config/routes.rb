Rails.application.routes.draw do
  get "carts/show"
  get "carts/add_item"
  get "carts/remove_item"
  get "carts/update_item"
  get "orders/index"
  get "orders/products"
  get "orders/cart"
  get "orders/checkout"

  root "home#index"
  # Webhook
  namespace :webhooks do
    post 'lstep', to: 'lstep#create'
    post 'lstep/purchase', to: 'lstep#purchase'
  end

  # Devise（registrationは除外してカスタム実装）
  devise_for :users, skip: [:registrations], controllers: {
    sessions:      'users/sessions',
    passwords:     'users/passwords',
    confirmations: 'users/confirmations',
    unlocks:       'users/unlocks'
  }

  # カスタム新規登録ルート
  devise_scope :user do
    get '/users/sign_up', to: 'users/registrations#new', as: :new_user_registration
    post '/users', to: 'users/registrations#create', as: :user_registration
  end

  # トップページと各種ページ
  get 'terms',   to: 'home#terms',   as: :terms
  get 'privacy', to: 'home#privacy', as: :privacy
  get 'law',     to: 'home#law',     as: :law

  # お問い合わせ
  resources :inquiries, only: [:new, :create]

  # 管理者画面
  namespace :admin do
    root to: 'dashboard#index'  # /admin → ダッシュボード
    resources :sales, only: [:index]
    resources :products, only: [:index, :edit, :update] do
      member do
        get :price_info
      end
    end
    resources :bonuses, only: [:index]
    resources :purchases, only: [:index, :edit, :update, :new, :create]

    resources :users, only: [:index, :show, :edit, :update] do
      resources :bonuses, only: [:index], controller: 'users/bonuses'
      member do
        patch :deactivate
        patch :suspend
        patch :reactivate
        get :sales_details  # 売上明細ページ
      end
      collection do
        get :all_users
      end
    end
    resources :inquiries, only: [:index, :show] do
      resources :answers, only: [:new, :create, :edit, :update, :destroy]
    end
    
    # システム状態管理
    resource :system_health, only: [:show], controller: 'system_health' do
      post :check
      get :api_status
    end
    
    # 請求書管理
    resource :invoice_recipient, only: [:show, :new, :create, :edit, :update, :destroy]
    get 'invoice_recipients', to: 'invoice_recipients#index'
    
    # 請求書状況管理
    resources :invoice_status, only: [:index] do
      member do
        patch :update_status
        get :show_receipt    # 領収書表示
        post :send_receipt   # 領収書送信
      end
    end
  end

  # 紹介機能
  resources :referrals, only: [:index, :show] do
    member do
      get :qr_code
    end
  end
  
  # 紹介招待機能
  resources :referral_invitations, only: [:index, :new, :create, :show]

  # 一般ユーザー用マイページ
  get 'mysales', to: 'users#mysales', as: :mysales
  resources :users, only: [:show] do  # /users/:id → 下位ユーザー詳細
    member do
      get :purchases  # /users/:id/purchases → 販売履歴
    end
  end
  get 'sales/:id' => "sales#show"
  resources :sales, only: [:index]
  # resources :customers, only: [:show] # Customerモデル削除により無効化
  
  # 予約・注文システム
  resources :orders, only: [:index] do
    collection do
      get :products      # 商品一覧
      get :checkout      # 購入確認
      post :purchase     # 購入処理
    end
  end
  
  # 支払い処理
  resources :payments, only: [] do
    collection do
      get :select_method    # 支払い方法選択
      post :bank_transfer   # 銀行振込処理
      post :credit_card     # クレジットカード処理
    end
  end
  
  # カート機能
  resource :cart, only: [:show] do
    member do
      post :add_item
      patch :update_item
      delete :remove_item
    end
  end
  
  
  
  # 請求書管理
  resources :invoices, only: [:index, :show, :new, :create, :edit, :update] do
    collection do
      get :history      # 請求書履歴
      get :issue        # 請求書発行
      get :settings     # 請求書情報入力・変更
      post :settings    # 請求書情報保存
    end
    member do
      patch :send_invoice     # 請求書送付
      get :receipt           # 領収書確認画面
      post :send_receipt     # 領収書送付
      patch :request_receipt # 領収書発行依頼
    end
  end

  # ヘルスチェック
  get "up", to: "rails/health#show", as: :rails_health_check

  # HTTPS強制リダイレクト（本番環境のみ）
  # Herokuでは自動的にHTTPS対応されるため、通常は不要
  # 独自ドメインを使用する場合のみ有効化
  # constraints(host: 'your-custom-domain.com') do
  #   get '(*path)', to: redirect { |params, req|
  #     "https://your-custom-domain.com/#{params[:path]}"
  #   }
  # end
end
