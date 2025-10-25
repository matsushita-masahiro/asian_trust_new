# カート住所選択機能 設計書

## Overview

カート画面でユーザーが登録住所と配送先住所をラジオボタンで選択できる機能の設計。既存のカート機能に住所選択UIを統合し、選択した住所を注文処理に正確に反映する。商品の種類（WOTT商品、その他商品）に応じて適切な住所選択オプションを提供する。

## Architecture

### システム構成
```
Cart View (show.html.erb)
├── Address Selection Component
│   ├── Radio Button UI
│   ├── Address Display
│   └── Validation Logic
├── JavaScript Controller
│   ├── Address Selection Handler
│   ├── UI Update Logic
│   └── Form Submission Handler
└── Order Processing Integration
    ├── Parameter Passing
    └── Address Validation
```

### データフロー
1. カート画面読み込み時：ユーザーの住所情報を取得・表示
2. 住所選択時：JavaScript でUI更新、選択状態を管理
3. 注文手続き時：選択された住所情報をパラメータとして渡す
4. 注文処理：受け取った住所情報で配送先を設定

## Components and Interfaces

### 1. Address Selection Component (View)

#### 住所選択UI構造
```erb
<div class="address-selection">
  <!-- 登録住所オプション -->
  <% if current_user.registration_address&.address.present? %>
    <div class="form-check">
      <input class="form-check-input" type="radio" 
             name="address_type" id="registration_address" 
             value="registration" <%= checked_condition %>>
      <label class="form-check-label" for="registration_address">
        <strong>登録住所</strong>
        <div class="text-muted small">
          〒<%= current_user.registration_address.postal_code %><br>
          <%= current_user.registration_address.address %>
        </div>
      </label>
    </div>
  <% end %>
  
  <!-- 配送先住所オプション -->
  <% if current_user.shipping_address&.address.present? %>
    <div class="form-check">
      <input class="form-check-input" type="radio" 
             name="address_type" id="shipping_address" 
             value="shipping" <%= checked_condition %>>
      <label class="form-check-label" for="shipping_address">
        <strong>配送先住所</strong>
        <div class="text-muted small">
          〒<%= current_user.shipping_address.postal_code %><br>
          <%= current_user.shipping_address.address %>
        </div>
      </label>
    </div>
  <% end %>
  
  <!-- 選択された住所の表示 -->
  <div class="alert alert-info" id="selected-address-display">
    <i class="fas fa-map-marker-alt me-2"></i>
    <strong>配送先住所:</strong>
    <div id="selected-address-content">
      <!-- JavaScript で動的更新 -->
    </div>
  </div>
</div>
```

#### 住所選択ロジック
```ruby
# 住所の存在チェック
registration_addr = current_user.registration_address
shipping_addr = current_user.shipping_address
has_registration = registration_addr&.postal_code.present? && registration_addr&.address.present?
has_shipping = shipping_addr&.postal_code.present? && shipping_addr&.address.present?

# デフォルト選択ロジック
default_selection = if has_shipping
                     'shipping'  # 配送先住所を優先
                   elsif has_registration
                     'registration'  # 登録住所をフォールバック
                   else
                     nil  # 住所未登録
                   end
```

### 2. JavaScript Controller

#### 住所選択管理
```javascript
class CartAddressSelector {
  constructor() {
    this.registrationAddress = {
      postal_code: '<%= current_user.registration_address&.postal_code %>',
      address: '<%= current_user.registration_address&.address %>',
      exists: <%= current_user.registration_address&.address.present? %>
    };
    
    this.shippingAddress = {
      postal_code: '<%= current_user.shipping_address&.postal_code %>',
      address: '<%= current_user.shipping_address&.address %>',
      exists: <%= current_user.shipping_address&.address.present? %>
    };
    
    this.initializeEventListeners();
    this.updateSelectedAddressDisplay();
  }
  
  initializeEventListeners() {
    const addressRadios = document.querySelectorAll('input[name="address_type"]');
    addressRadios.forEach(radio => {
      radio.addEventListener('change', () => this.handleAddressChange(radio.value));
    });
  }
  
  handleAddressChange(addressType) {
    this.updateSelectedAddressDisplay(addressType);
    this.validateCheckoutButton();
  }
  
  updateSelectedAddressDisplay(addressType) {
    const contentElement = document.getElementById('selected-address-content');
    if (!contentElement) return;
    
    let addressHtml = '';
    if (addressType === 'registration' && this.registrationAddress.exists) {
      addressHtml = `〒${this.registrationAddress.postal_code}<br>${this.registrationAddress.address}`;
    } else if (addressType === 'shipping' && this.shippingAddress.exists) {
      addressHtml = `〒${this.shippingAddress.postal_code}<br>${this.shippingAddress.address}`;
    }
    
    contentElement.innerHTML = addressHtml;
  }
  
  validateCheckoutButton() {
    const checkoutBtn = document.getElementById('checkout-btn');
    const selectedAddress = document.querySelector('input[name="address_type"]:checked');
    const hasAddress = this.registrationAddress.exists || this.shippingAddress.exists;
    
    if (hasAddress && selectedAddress) {
      checkoutBtn.disabled = false;
      checkoutBtn.textContent = '購入手続きへ';
      checkoutBtn.className = 'btn btn-success btn-lg';
    } else {
      checkoutBtn.disabled = true;
      checkoutBtn.textContent = hasAddress ? '配送先を選択してください' : '住所登録が必要です';
      checkoutBtn.className = 'btn btn-secondary btn-lg';
    }
  }
}
```

### 3. 商品種類別の住所選択パターン

#### パターン1: 通常商品の住所選択
```erb
<!-- シンプルな住所選択 -->
<div class="delivery-option">
  <label class="form-label fw-bold">
    <i class="fas fa-home me-2"></i>
    配送先住所を選択してください
  </label>
  <!-- 住所選択ラジオボタン -->
  <!-- 選択された住所の表示 -->
</div>
```

#### パターン2: 複数商品種類の混在時
```erb
<!-- WOTT商品の配送先（クリニック選択） -->
<div class="delivery-option">
  <label>骨髄幹細胞培培養上清液の配送先クリニック</label>
  <select name="clinic_id">...</select>
</div>

<!-- 通常商品の住所選択 -->
<div class="delivery-option">
  <label>配送先住所を選択してください</label>
  <!-- 住所選択ラジオボタン -->
</div>
```

## Data Models

### 住所情報の取得
```ruby
# Userモデルから住所情報を取得
user = current_user
registration_address = user.registration_address
shipping_address = user.shipping_address

# 住所の有効性チェック
def address_valid?(address)
  address&.postal_code.present? && address&.address.present?
end
```

### パラメータ構造
```ruby
# 注文処理に渡すパラメータ
checkout_params = {
  delivery_type: 'home',        # 'home', 'clinic', 'multiple'
  address_type: 'shipping',     # 'registration', 'shipping'
  clinic_id: nil                # クリニック配送の場合のみ
}

# 例: orders/checkout?delivery_type=home&address_type=shipping
```

## Error Handling

### 住所未登録時の処理
```erb
<% if !has_registration && !has_shipping %>
  <div class="alert alert-danger">
    <i class="fas fa-exclamation-triangle me-2"></i>
    <strong>住所未登録:</strong>
    <div class="mt-2">
      住所が登録されていません。
      <%= link_to "マイアカウント", user_path(current_user, from: 'cart'), 
                  class: "text-decoration-underline" %>から住所を登録してください。
    </div>
  </div>
<% end %>
```

### JavaScript エラーハンドリング
```javascript
try {
  // 住所選択処理
  this.handleAddressChange(addressType);
} catch (error) {
  console.error('Address selection error:', error);
  // ユーザーにエラーメッセージを表示
  this.showErrorMessage('住所選択でエラーが発生しました。ページを再読み込みしてください。');
}
```

## Testing Strategy

### 1. View テスト
- 住所選択ラジオボタンの表示確認
- 住所情報の正確な表示
- 住所未登録時のメッセージ表示

### 2. JavaScript テスト
- 住所選択時のUI更新
- チェックアウトボタンの状態変更
- エラーハンドリング

### 3. 統合テスト
- 住所選択から注文処理までのフロー
- 商品種類別の住所選択パターン
- パラメータの正確な受け渡し

## User Interface Design

### 住所選択UI の視覚的階層
```
配送先選択カード
├── カードヘッダー（アイコン + タイトル）
├── 商品種類別の説明（必要に応じて）
├── 住所選択セクション
│   ├── 登録住所オプション
│   │   ├── ラジオボタン
│   │   ├── 住所タイプラベル
│   │   └── 住所詳細（郵便番号 + 住所）
│   └── 配送先住所オプション
│       ├── ラジオボタン
│       ├── 住所タイプラベル
│       └── 住所詳細（郵便番号 + 住所）
└── 選択された住所の確認表示
    ├── アイコン + 「配送先住所」ラベル
    └── 選択された住所の詳細
```

### スタイリング方針
- Bootstrap のフォームコンポーネントを活用
- 視覚的な階層を明確にするためのカード構造
- 選択状態を明確にするためのハイライト
- アクセシビリティを考慮したラベル設計

### レスポンシブ対応
- モバイル端末での住所表示の最適化
- タッチ操作に適したボタンサイズ
- 長い住所テキストの適切な改行処理

## Security Considerations

### パラメータ検証
```ruby
# コントローラーでのパラメータ検証
def validate_address_params
  address_type = params[:address_type]
  return false unless %w[registration shipping].include?(address_type)
  
  case address_type
  when 'registration'
    current_user.registration_address&.address.present?
  when 'shipping'
    current_user.shipping_address&.address.present?
  end
end
```

### XSS 対策
- 住所情報の適切なエスケープ処理
- JavaScript での動的コンテンツ生成時のサニタイゼーション

### CSRF 対策
- フォーム送信時のCSRFトークン検証
- Ajax リクエストでのトークン送信

## Performance Considerations

### データベースクエリ最適化
```ruby
# N+1 クエリを避けるための includes
@user = User.includes(:registration_address, :shipping_address).find(current_user.id)
```

### JavaScript パフォーマンス
- イベントリスナーの適切な管理（重複登録の防止）
- DOM 操作の最小化
- Turbo 対応のためのイベントハンドリング

### キャッシュ戦略
- 住所情報の適切なキャッシュ
- JavaScript ファイルのブラウザキャッシュ活用

## Integration Points

### 注文処理との連携
```ruby
# orders_controller.rb での住所情報取得
def get_delivery_address
  address_type = params[:address_type]
  case address_type
  when 'registration'
    current_user.registration_address
  when 'shipping'
    current_user.shipping_address
  else
    nil
  end
end
```

### 住所管理機能との連携
- 住所更新時のカート画面への反映
- 住所削除時の適切なフォールバック処理

### 既存システムとの互換性
- 既存の配送先選択ロジックとの整合性
- レガシーコードとの共存