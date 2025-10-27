# 郵便番号自動住所入力機能 使用方法ガイド

## 概要

郵便番号自動住所入力機能は、ユーザーが郵便番号を入力すると自動的に住所情報を取得して入力フィールドに反映するJavaScript機能です。zipcloud APIを使用して日本の郵便番号から住所を取得します。

## 基本的な使用方法

### 1. 既存のフォームでの利用

現在、この機能は `app/views/users/show.html.erb` の住所入力フォームで利用されています。

```html
<!-- 郵便番号入力フィールド -->
<%= f.text_field :postal_code, 
    class: "form-control form-control-sm postal-code-input", 
    placeholder: "例: 123-4567",
    data: { address_type: "registration" } %>

<!-- 住所入力フィールド -->
<%= f.text_area :address, 
    class: "form-control form-control-sm address-input", 
    rows: 2, 
    placeholder: "全住所を入力してください", 
    required: true,
    data: { address_type: "registration" } %>
```

### 2. 必要なHTML要素

郵便番号自動入力機能を動作させるには、以下の要素が必要です：

#### 必須要素
- **郵便番号入力フィールド**: `input[name*="postal_code"]`
- **住所入力フィールド**: `textarea[name*="address"]` または `input[name*="address"]`

#### UI要素（自動生成）
- **ローディングインジケーター**: `.postal-code-loading`
- **エラー表示**: `.postal-code-error`

### 3. JavaScript初期化

機能は `app/javascript/application.js` で自動的に初期化されます：

```javascript
import PostalCodeAutoFill from './postal_code_auto_fill.js';

document.addEventListener('DOMContentLoaded', function() {
  initializePostalCodeAutoFill();
});

document.addEventListener('turbo:load', function() {
  initializePostalCodeAutoFill();
});

function initializePostalCodeAutoFill() {
  // 登録住所用
  const registrationAutoFill = new PostalCodeAutoFill({
    postalCodeSelector: 'input[data-address-type="registration"][name*="postal_code"]',
    addressSelector: 'textarea[data-address-type="registration"][name*="address"]'
  });
  registrationAutoFill.init();

  // 配送先住所用
  const shippingAutoFill = new PostalCodeAutoFill({
    postalCodeSelector: 'input[data-address-type="shipping"][name*="postal_code"]',
    addressSelector: 'textarea[data-address-type="shipping"][name*="address"]'
  });
  shippingAutoFill.init();
}
```

## カスタマイズオプション

### PostalCodeAutoFillクラスのオプション

```javascript
const autoFill = new PostalCodeAutoFill({
  // 郵便番号フィールドのセレクター（デフォルト: 'input[name*="postal_code"]'）
  postalCodeSelector: 'input[name*="postal_code"]',
  
  // 住所フィールドのセレクター（デフォルト: 'textarea[name*="address"]'）
  addressSelector: 'textarea[name*="address"]',
  
  // 郵便番号API URL（デフォルト: 'https://zipcloud.ibsnet.co.jp/api/search'）
  apiUrl: 'https://zipcloud.ibsnet.co.jp/api/search',
  
  // デバウンス遅延時間（ミリ秒）（デフォルト: 500）
  debounceDelay: 500,
  
  // キャッシュ機能の有効/無効（デフォルト: true）
  enableCache: true,
  
  // ローディング表示の有効/無効（デフォルト: true）
  showLoadingIndicator: true,
  
  // APIタイムアウト時間（ミリ秒）（デフォルト: 5000）
  apiTimeout: 5000
});
```

### カスタマイズ例

#### 1. 異なるセレクターでの利用

```javascript
const customAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: '#custom-postal-code',
  addressSelector: '#custom-address',
  debounceDelay: 300 // より高速な応答
});
customAutoFill.init();
```

#### 2. キャッシュ無効化

```javascript
const noCacheAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[name="postal_code"]',
  addressSelector: 'input[name="address"]',
  enableCache: false // キャッシュを無効化
});
noCacheAutoFill.init();
```

#### 3. カスタムAPIエンドポイント

```javascript
const customApiAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[name="postal_code"]',
  addressSelector: 'input[name="address"]',
  apiUrl: 'https://your-custom-api.com/postal-code',
  apiTimeout: 10000 // 10秒のタイムアウト
});
customApiAutoFill.init();
```

## 他のフォームでの利用方法

### 1. 新しいフォームに追加

他のページで郵便番号自動入力機能を使用する場合：

#### HTML構造

```html
<div class="form-group">
  <label for="postal_code">郵便番号</label>
  <input type="text" 
         id="postal_code" 
         name="postal_code" 
         class="form-control postal-code-input"
         placeholder="例: 123-4567">
  
  <!-- ローディングインジケーター（自動生成されるため不要） -->
  <!-- エラー表示（自動生成されるため不要） -->
</div>

<div class="form-group">
  <label for="address">住所</label>
  <textarea id="address" 
            name="address" 
            class="form-control address-input"
            rows="3"
            placeholder="全住所を入力してください"></textarea>
</div>
```

#### JavaScript初期化

```javascript
document.addEventListener('DOMContentLoaded', function() {
  const autoFill = new PostalCodeAutoFill({
    postalCodeSelector: '#postal_code',
    addressSelector: '#address'
  });
  autoFill.init();
});
```

### 2. 複数フォームでの利用

同一ページに複数の住所フォームがある場合：

```javascript
document.addEventListener('DOMContentLoaded', function() {
  // 請求先住所
  const billingAutoFill = new PostalCodeAutoFill({
    postalCodeSelector: 'input[data-type="billing"][name*="postal_code"]',
    addressSelector: 'textarea[data-type="billing"][name*="address"]'
  });
  billingAutoFill.init();

  // 配送先住所
  const shippingAutoFill = new PostalCodeAutoFill({
    postalCodeSelector: 'input[data-type="shipping"][name*="postal_code"]',
    addressSelector: 'textarea[data-type="shipping"][name*="address"]'
  });
  shippingAutoFill.init();
});
```

### 3. 動的に追加されるフォームでの利用

JavaScript で動的に追加されるフォームの場合：

```javascript
function addAddressForm() {
  // フォームを動的に追加
  const formHtml = `
    <div class="address-form">
      <input type="text" name="postal_code" class="form-control">
      <textarea name="address" class="form-control"></textarea>
    </div>
  `;
  document.getElementById('forms-container').insertAdjacentHTML('beforeend', formHtml);
  
  // 新しく追加されたフォームに郵便番号自動入力機能を適用
  const newAutoFill = new PostalCodeAutoFill({
    postalCodeSelector: '.address-form:last-child input[name="postal_code"]',
    addressSelector: '.address-form:last-child textarea[name="address"]'
  });
  newAutoFill.init();
}
```

## イベントハンドリング

### カスタムイベント

郵便番号自動入力機能は以下のカスタムイベントを発火します：

#### 1. 住所更新イベント

```javascript
document.addEventListener('postalCodeAutoFill:addressUpdated', function(event) {
  console.log('住所が更新されました:', event.detail.addressData);
  console.log('郵便番号フィールド:', event.detail.postalCodeField);
  console.log('住所フィールド:', event.detail.addressField);
  
  // カスタム処理を追加
  // 例: 住所更新時に他のフィールドも更新
  updateRelatedFields(event.detail.addressData);
});
```

#### 2. 手動編集イベント

```javascript
document.addEventListener('postalCodeAutoFill:manualEdit', function(event) {
  console.log('住所が手動編集されました');
  console.log('元の値:', event.detail.originalValue);
  console.log('編集後の値:', event.detail.editedValue);
  console.log('編集履歴:', event.detail.editHistory);
});
```

### イベント活用例

```javascript
// 住所更新時に都道府県フィールドを自動設定
document.addEventListener('postalCodeAutoFill:addressUpdated', function(event) {
  const addressData = event.detail.addressData;
  const prefectureField = document.querySelector('#prefecture');
  
  if (prefectureField && addressData.prefecture) {
    prefectureField.value = addressData.prefecture;
  }
});

// 手動編集時に確認ダイアログを表示
document.addEventListener('postalCodeAutoFill:manualEdit', function(event) {
  if (event.detail.originalValue) {
    const confirmed = confirm('住所を手動で変更しますか？自動入力された内容が上書きされる可能性があります。');
    if (!confirmed) {
      event.detail.addressField.value = event.detail.originalValue;
    }
  }
});
```

## スタイルカスタマイズ

### CSS クラス

郵便番号自動入力機能で使用されるCSSクラス：

```css
/* ローディング状態 */
.postal-code-loading {
  display: none;
  color: #6c757d;
}

.postal-code-loading.show {
  display: block;
}

/* エラー表示 */
.postal-code-error {
  display: none;
  color: #dc3545;
}

.postal-code-error.show {
  display: block;
}

/* 郵便番号フィールドの状態 */
.postal-code-loading-state {
  background-color: #f8f9fa;
}

.postal-code-error-state {
  border-color: #dc3545;
  box-shadow: 0 0 0 0.2rem rgba(220, 53, 69, 0.25);
}

.postal-code-success-state {
  border-color: #28a745;
  box-shadow: 0 0 0 0.2rem rgba(40, 167, 69, 0.25);
}

/* 手動編集状態 */
.postal-code-manually-edited {
  border-left: 3px solid #ffc107;
}

/* デバウンス中の状態 */
.postal-code-debouncing {
  border-color: #6c757d;
  transition: border-color 0.2s ease;
}
```

### カスタムスタイル例

```css
/* カスタムローディングアニメーション */
.postal-code-loading .fa-spinner {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* カスタムエラースタイル */
.postal-code-error {
  background-color: #f8d7da;
  border: 1px solid #f5c6cb;
  border-radius: 0.25rem;
  padding: 0.375rem 0.75rem;
  margin-top: 0.25rem;
}

/* 成功時のアニメーション */
.postal-code-success-state {
  animation: successPulse 0.5s ease-in-out;
}

@keyframes successPulse {
  0% { transform: scale(1); }
  50% { transform: scale(1.02); }
  100% { transform: scale(1); }
}
```

## トラブルシューティング

### よくある問題と解決方法

#### 1. 住所が自動入力されない

**原因と解決方法:**
- セレクターが正しく設定されているか確認
- 郵便番号が7桁の数字であることを確認
- ネットワーク接続を確認
- ブラウザの開発者ツールでエラーを確認

```javascript
// デバッグ用のログを有効化
const autoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[name="postal_code"]',
  addressSelector: 'textarea[name="address"]'
});

// 初期化の成功/失敗を確認
if (autoFill.init()) {
  console.log('郵便番号自動入力機能が正常に初期化されました');
} else {
  console.error('郵便番号自動入力機能の初期化に失敗しました');
}
```

#### 2. エラーメッセージが表示される

**一般的なエラーと対処法:**

- **「正しい郵便番号を入力してください」**: 7桁の数字で入力
- **「該当する住所が見つかりませんでした」**: 存在する郵便番号を入力
- **「住所の取得に失敗しました」**: ネットワーク接続を確認

#### 3. 手動編集が正しく動作しない

```javascript
// 手動編集状態を確認
document.addEventListener('postalCodeAutoFill:manualEdit', function(event) {
  console.log('手動編集状態:', event.detail);
});
```

#### 4. Turboとの互換性問題

Turboを使用している場合は、`turbo:load` イベントでも初期化を行う：

```javascript
document.addEventListener('turbo:load', function() {
  initializePostalCodeAutoFill();
});
```

### デバッグ方法

#### 1. ブラウザ開発者ツールでの確認

```javascript
// コンソールで直接テスト
const testAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[name="postal_code"]',
  addressSelector: 'textarea[name="address"]'
});

// 初期化テスト
console.log('初期化結果:', testAutoFill.init());

// キャッシュ状態確認
console.log('キャッシュ統計:', testAutoFill.getCacheStats());

// API呼び出し統計確認
console.log('API統計:', testAutoFill.getApiCallStats());
```

#### 2. ネットワークタブでAPI呼び出し確認

1. 開発者ツールのNetworkタブを開く
2. 郵便番号を入力
3. `zipcloud.ibsnet.co.jp` へのリクエストを確認
4. レスポンス内容を確認

## パフォーマンス最適化

### 1. キャッシュ設定の調整

```javascript
const optimizedAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[name="postal_code"]',
  addressSelector: 'textarea[name="address"]',
  enableCache: true,
  debounceDelay: 300 // より高速な応答
});
```

### 2. API呼び出し制限の調整

デフォルトでは1分間に30回までのAPI呼び出し制限があります。必要に応じて調整可能です。

### 3. メモリ使用量の監視

```javascript
// メモリ使用量を定期的に確認
setInterval(() => {
  if (performance.memory) {
    console.log('メモリ使用量:', {
      used: Math.round(performance.memory.usedJSHeapSize / 1024 / 1024) + 'MB',
      total: Math.round(performance.memory.totalJSHeapSize / 1024 / 1024) + 'MB'
    });
  }
}, 30000); // 30秒ごと
```

## セキュリティ考慮事項

### 1. HTTPS通信の確保

郵便番号APIとの通信は必ずHTTPS経由で行われます。

### 2. 入力サニタイゼーション

郵便番号入力は数字とハイフンのみが許可され、その他の文字は自動的に除去されます。

### 3. XSS対策

DOM操作時は適切なエスケープ処理が行われます。

## ライセンスと利用規約

### zipcloud API利用規約

この機能は zipcloud API (https://zipcloud.ibsnet.co.jp/) を使用しています。
利用時は zipcloud の利用規約を遵守してください。

### 利用制限

- 1分間に30回までのAPI呼び出し制限
- 商用利用可能
- 大量アクセス時は事前相談推奨

## サポート

### 問題報告

機能に関する問題や改善提案は、プロジェクトのIssueトラッカーまでご報告ください。

### 更新履歴

- v1.0.0: 初回リリース
  - 基本的な郵便番号自動入力機能
  - キャッシュ機能
  - エラーハンドリング
  - 手動編集対応
  - Turbo対応