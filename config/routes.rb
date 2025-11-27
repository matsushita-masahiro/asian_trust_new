Rails.application.routes.draw do
  # クリニック予約
  resources :purchases, only: [] do
    resources :clinic_reservations, only: [:new, :create]
  end
  resources :clinic_reservations, only: [:index, :show, :edit, :update, :destroy]
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
    # 紹介者経由の新規登録
    get '/signup', to: 'users/registrations#new_with_referrer', as: :signup_with_referrer
  end

  # トップページと各種ページ
  get 'terms',   to: 'home#terms',   as: :terms
  get 'privacy', to: 'home#privacy', as: :privacy
  get 'law',     to: 'home#law',     as: :law

  # お問い合わせ
  resources :inquiries, only: [:new, :create]

  # 管理者画面
  namespace :admin do
    resources :clinic_reservations, only: [:index, :show, :edit, :update, :destroy] do
      member do
        patch :confirm
        patch :complete
        patch :cancel
      end
    end
    root to: 'dashboard#index'  # /admin → ダッシュボード
    resources :sales, only: [:index]
    resources :products, only: [:index, :edit, :update, :destroy] do
      member do
        get :price_info
        patch :restore
      end
    end
    resources :bonuses, only: [:index]
    resources :incentives, only: [:index, :show] do
      member do
        get :drill_down
        get :breakdown
      end
    end
    resources :purchases, only: [:index, :show, :edit, :update, :new, :create] do
      member do
        patch :confirm_payment
      end
      collection do
        get :get_user_level_price
      end
      resources :purchase_invoices, only: [:new, :create]
    end
    
    resources :purchase_items, only: [:edit, :update]

    resources :users, only: [:index, :show, :edit, :update] do
      resources :bonuses, only: [:index], controller: 'users/bonuses'
      # 管理者用住所管理
      resources :addresses, only: [:create, :update, :destroy]
      member do
        patch :deactivate
        patch :suspend
        patch :reactivate
        patch :certify  # アドバイザー認定
        get :sales_details  # 売上明細ページ
      end
      collection do
        get :all_users
        get :advisor_pre_list  # アドバイザー認定前一覧
      end
    end
    
    # レベル変更申請管理
    resources :level_change_applications, only: [:index, :show] do
      member do
        patch :cancel
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
    
    # 請求書管理（インセンティブ用）
    resource :invoice_recipient, only: [:show, :new, :create, :edit, :update, :destroy]
    get 'invoice_recipients', to: 'invoice_recipients#index'
    
    # 請求書状況管理（インセンティブ用）
    resources :invoice_status, only: [:index] do
      member do
        patch :update_status
        get :show_receipt    # 領収書表示
        post :send_receipt   # 領収書送信
      end
    end
    
    # 購入請求書管理
    resources :purchase_invoices, only: [:index, :show, :edit, :update] do
      member do
        patch :send_invoice      # 請求書送付
        patch :confirm_payment   # 支払い確認
        patch :send_receipt      # 領収書発行
      end
    end
    
    # アドバイザー認定前管理
    resources :advisor_pre_certifications, only: [:index, :show] do
      member do
        patch :certify  # アドバイザーに認定
      end
    end
    
    # WOTTレベル昇格申請管理
    resources :wott_level_upgrade_requests, only: [:index, :show] do
      member do
        post :approve  # 承認
        post :reject   # 却下
      end
    end
  end

  # インセンティブ機能
  resources :incentives, only: [:index, :show] do
    member do
      get :drill_down
      get :breakdown  # インセンティブ明細画面
      get :export
    end
    collection do
      get :hierarchy
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

  # 階層図機能
  get 'hierarchy', to: 'hierarchy#index', as: :hierarchy

  # 一般ユーザー用マイページ
  get 'mysales', to: 'users#mysales', as: :mysales
  resources :users, only: [:show, :update] do  # /users/:id → 下位ユーザー詳細
    member do
      get :purchases  # /users/:id/purchases → 販売履歴
    end
    # 住所管理
    resources :addresses, only: [:create, :update, :destroy]
  end
  
  # 購入履歴機能
  resources :purchases, only: [:index, :show] do
    collection do
      get :my_history  # /purchases/my_history → 自分の購入履歴一覧
    end
  end
  
  # 購入関連
  resources :purchases, only: [] do
    member do
      patch :reserve_clinic
    end
    resources :purchase_invoices, only: [:new, :create]
  end
  get 'sales/:id' => "sales#show"
  resources :sales, only: [:index]
  # resources :customers, only: [:show] # Customerモデル削除により無効化
  
  # 購入請求書
  resources :purchase_invoices, only: [:index, :show, :edit, :update] do
    member do
      patch :send_invoice      # 請求書送付（管理者のみ）
      patch :confirm_payment   # 支払い確認（管理者のみ）
      patch :request_receipt   # 領収書発行依頼
      patch :send_receipt      # 領収書発行（管理者のみ）
      patch :mark_as_paid      # 振込済み報告（購入者のみ）
    end
  end
  
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
  
  # デバッグ用（一時的）
  get "debug/mailer", to: "debug#mailer_check" if Rails.env.production?

  # HTTPS強制リダイレクト（本番環境のみ）
  # Herokuでは自動的にHTTPS対応されるため、通常は不要
  # 独自ドメインを使用する場合のみ有効化
  # constraints(host: 'your-custom-domain.com') do
  #   get '(*path)', to: redirect { |params, req|
  #     "https://your-custom-domain.com/#{params[:path]}"
  #   }
  # end
end
