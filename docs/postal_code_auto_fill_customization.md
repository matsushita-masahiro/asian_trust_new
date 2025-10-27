# 郵便番号自動住所入力機能 カスタマイズオプション

## 概要

郵便番号自動住所入力機能は豊富なカスタマイズオプションを提供し、様々なプロジェクトの要件に対応できます。このドキュメントでは、利用可能なすべてのカスタマイズオプションと実装例を詳しく説明します。

## 基本設定オプション

### PostalCodeAutoFillクラスのコンストラクターオプション

```javascript
const autoFill = new PostalCodeAutoFill({
  // === セレクター設定 ===
  postalCodeSelector: 'input[name*="postal_code"]',  // 郵便番号フィールドのセレクター
  addressSelector: 'textarea[name*="address"]',      // 住所フィールドのセレクター
  
  // === API設定 ===
  apiUrl: 'https://zipcloud.ibsnet.co.jp/api/search', // 郵便番号API URL
  apiTimeout: 5000,                                   // APIタイムアウト時間（ミリ秒）
  
  // === パフォーマンス設定 ===
  debounceDelay: 500,      // デバウンス遅延時間（ミリ秒）
  enableCache: true,       // キャッシュ機能の有効/無効
  
  // === UI設定 ===
  showLoadingIndicator: true,  // ローディングインジケーターの表示
  
  // === 国際化設定 ===
  messages: {              // カスタムメッセージ（オプション）
    loading: '住所を取得中...',
    invalidFormat: '郵便番号の形式が正しくありません',
    notFound: '該当する住所が見つかりませんでした',
    networkError: '住所の取得に失敗しました',
    timeout: 'リクエストがタイムアウトしました'
  }
});
```

## セレクターのカスタマイズ

### 1. 基本的なセレクター指定

```javascript
// ID指定
const idAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: '#postal-code',
  addressSelector: '#address'
});

// クラス指定
const classAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: '.postal-code-input',
  addressSelector: '.address-input'
});

// 属性指定
const attrAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[data-type="postal-code"]',
  addressSelector: 'textarea[data-type="address"]'
});
```

### 2. 複雑なセレクター

```javascript
// 特定のフォーム内のフィールドのみ対象
const formScopedAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: '#user-registration-form input[name="postal_code"]',
  addressSelector: '#user-registration-form textarea[name="address"]'
});

// 複数の条件を組み合わせ
const complexAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[name*="postal_code"]:not([disabled])',
  addressSelector: 'textarea[name*="address"]:not([readonly])'
});

// data属性による区別
const dataAttrAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[data-address-type="billing"][name*="postal_code"]',
  addressSelector: 'textarea[data-address-type="billing"][name*="address"]'
});
```

## パフォーマンス設定のカスタマイズ

### 1. デバウンス設定

```javascript
// 高速応答（短いデバウンス）
const fastAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[name="postal_code"]',
  addressSelector: 'textarea[name="address"]',
  debounceDelay: 200  // 200ms
});

// 慎重な応答（長いデバウンス）
const cautiousAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[name="postal_code"]',
  addressSelector: 'textarea[name="address"]',
  debounceDelay: 1000  // 1秒
});

// デバウンス無効化（即座に反応）
const immediateAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[name="postal_code"]',
  addressSelector: 'textarea[name="address"]',
  debounceDelay: 0
});
```

### 2. キャッシュ設定

```javascript
// キャッシュ有効（デフォルト）
const cachedAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[name="postal_code"]',
  addressSelector: 'textarea[name="address"]',
  enableCache: true
});

// キャッシュ無効（常に最新データを取得）
const noCacheAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[name="postal_code"]',
  addressSelector: 'textarea[name="address"]',
  enableCache: false
});
```

### 3. API設定

```javascript
// カスタムAPIエンドポイント
const customApiAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[name="postal_code"]',
  addressSelector: 'textarea[name="address"]',
  apiUrl: 'https://your-custom-api.com/postal-lookup',
  apiTimeout: 10000  // 10秒のタイムアウト
});

// 短いタイムアウト（高速応答重視）
const quickTimeoutAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[name="postal_code"]',
  addressSelector: 'textarea[name="address"]',
  apiTimeout: 2000  // 2秒
});
```

## UI表示のカスタマイズ

### 1. ローディングインジケーター

```javascript
// ローディング表示有効（デフォルト）
const loadingAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[name="postal_code"]',
  addressSelector: 'textarea[name="address"]',
  showLoadingIndicator: true
});

// ローディング表示無効
const noLoadingAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[name="postal_code"]',
  addressSelector: 'textarea[name="address"]',
  showLoadingIndicator: false
});
```

### 2. カスタムメッセージ

```javascript
// 日本語メッセージ
const japaneseAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[name="postal_code"]',
  addressSelector: 'textarea[name="address"]',
  messages: {
    loading: '住所を検索しています...',
    invalidFormat: '郵便番号は7桁の数字で入力してください（例: 123-4567）',
    notFound: '入力された郵便番号に該当する住所が見つかりませんでした',
    networkError: 'ネットワークエラーが発生しました。手動で住所を入力してください',
    timeout: '住所の取得に時間がかかっています。しばらくお待ちください'
  }
});

// 英語メッセージ
const englishAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[name="postal_code"]',
  addressSelector: 'textarea[name="address"]',
  messages: {
    loading: 'Fetching address...',
    invalidFormat: 'Please enter a valid postal code (e.g., 123-4567)',
    notFound: 'No address found for the entered postal code',
    networkError: 'Network error occurred. Please enter address manually',
    timeout: 'Request timed out. Please try again'
  }
});
```

## 複数フォーム対応のカスタマイズ

### 1. 請求先・配送先住所の分離

```javascript
// 請求先住所用
const billingAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[data-address-type="billing"][name*="postal_code"]',
  addressSelector: 'textarea[data-address-type="billing"][name*="address"]',
  debounceDelay: 300
});

// 配送先住所用
const shippingAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[data-address-type="shipping"][name*="postal_code"]',
  addressSelector: 'textarea[data-address-type="shipping"][name*="address"]',
  debounceDelay: 300
});

// 両方を初期化
billingAutoFill.init();
shippingAutoFill.init();
```

### 2. 動的フォーム対応

```javascript
class DynamicPostalCodeManager {
  constructor() {
    this.instances = [];
  }
  
  addForm(formId) {
    const autoFill = new PostalCodeAutoFill({
      postalCodeSelector: `#${formId} input[name*="postal_code"]`,
      addressSelector: `#${formId} textarea[name*="address"]`,
      debounceDelay: 400
    });
    
    if (autoFill.init()) {
      this.instances.push({
        formId: formId,
        instance: autoFill
      });
    }
  }
  
  removeForm(formId) {
    const index = this.instances.findIndex(item => item.formId === formId);
    if (index !== -1) {
      this.instances[index].instance.destroy();
      this.instances.splice(index, 1);
    }
  }
  
  destroyAll() {
    this.instances.forEach(item => item.instance.destroy());
    this.instances = [];
  }
}

// 使用例
const manager = new DynamicPostalCodeManager();
manager.addForm('address-form-1');
manager.addForm('address-form-2');
```

## イベントハンドリングのカスタマイズ

### 1. 住所更新時のカスタム処理

```javascript
document.addEventListener('postalCodeAutoFill:addressUpdated', function(event) {
  const { addressData, postalCodeField, addressField } = event.detail;
  
  // 都道府県フィールドの自動設定
  const prefectureField = document.querySelector('#prefecture');
  if (prefectureField && addressData.prefecture) {
    prefectureField.value = addressData.prefecture;
    prefectureField.dispatchEvent(new Event('change'));
  }
  
  // 市区町村フィールドの自動設定
  const cityField = document.querySelector('#city');
  if (cityField && addressData.city) {
    cityField.value = addressData.city;
    cityField.dispatchEvent(new Event('change'));
  }
  
  // カスタム処理
  updateShippingFee(addressData.prefecture);
  showRegionalInfo(addressData);
  
  // Google Analytics イベント送信
  if (typeof gtag !== 'undefined') {
    gtag('event', 'postal_code_auto_fill', {
      event_category: 'form_interaction',
      event_label: 'address_updated',
      postal_code: addressData.zipcode
    });
  }
});

function updateShippingFee(prefecture) {
  // 都道府県に基づく配送料計算
  const shippingFeeElement = document.querySelector('#shipping-fee');
  if (shippingFeeElement) {
    const fee = calculateShippingFee(prefecture);
    shippingFeeElement.textContent = `¥${fee.toLocaleString()}`;
  }
}

function showRegionalInfo(addressData) {
  // 地域別の特別情報表示
  const infoElement = document.querySelector('#regional-info');
  if (infoElement) {
    const info = getRegionalInfo(addressData.prefecture);
    infoElement.innerHTML = info;
  }
}
```

### 2. 手動編集時のカスタム処理

```javascript
document.addEventListener('postalCodeAutoFill:manualEdit', function(event) {
  const { originalValue, editedValue, addressField } = event.detail;
  
  // 編集履歴の保存
  saveEditHistory({
    timestamp: new Date().toISOString(),
    original: originalValue,
    edited: editedValue,
    fieldId: addressField.id
  });
  
  // 視覚的フィードバック
  addressField.classList.add('manually-edited');
  
  // 確認ダイアログ（オプション）
  if (originalValue && originalValue !== editedValue) {
    const confirmed = confirm(
      '住所を手動で変更しますか？\n' +
      '自動入力された内容が上書きされる可能性があります。'
    );
    
    if (!confirmed) {
      addressField.value = originalValue;
      addressField.classList.remove('manually-edited');
    }
  }
  
  // 分析データの送信
  if (typeof gtag !== 'undefined') {
    gtag('event', 'manual_address_edit', {
      event_category: 'form_interaction',
      event_label: 'address_manually_edited'
    });
  }
});

function saveEditHistory(editData) {
  // LocalStorageに編集履歴を保存
  const history = JSON.parse(localStorage.getItem('addressEditHistory') || '[]');
  history.push(editData);
  
  // 最新100件のみ保持
  if (history.length > 100) {
    history.splice(0, history.length - 100);
  }
  
  localStorage.setItem('addressEditHistory', JSON.stringify(history));
}
```

## スタイルのカスタマイズ

### 1. CSS変数を使用したテーマ設定

```css
/* カスタムテーマの定義 */
:root {
  --postal-code-primary-color: #007bff;
  --postal-code-success-color: #28a745;
  --postal-code-error-color: #dc3545;
  --postal-code-warning-color: #ffc107;
  --postal-code-loading-color: #6c757d;
}

/* ダークテーマ */
[data-theme="dark"] {
  --postal-code-primary-color: #0d6efd;
  --postal-code-success-color: #198754;
  --postal-code-error-color: #dc3545;
  --postal-code-warning-color: #ffc107;
  --postal-code-loading-color: #adb5bd;
}

/* カスタムスタイル */
.postal-code-loading {
  color: var(--postal-code-loading-color);
  font-size: 0.875rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.postal-code-error {
  color: var(--postal-code-error-color);
  font-size: 0.875rem;
  background-color: rgba(220, 53, 69, 0.1);
  border: 1px solid rgba(220, 53, 69, 0.2);
  border-radius: 0.25rem;
  padding: 0.5rem;
  margin-top: 0.25rem;
}

.postal-code-success-state {
  border-color: var(--postal-code-success-color);
  box-shadow: 0 0 0 0.2rem rgba(40, 167, 69, 0.25);
}

.postal-code-manually-edited {
  border-left: 3px solid var(--postal-code-warning-color);
  background-color: rgba(255, 193, 7, 0.05);
}
```

### 2. アニメーション効果

```css
/* ローディングアニメーション */
.postal-code-loading .spinner {
  display: inline-block;
  width: 1rem;
  height: 1rem;
  border: 2px solid transparent;
  border-top: 2px solid var(--postal-code-loading-color);
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* 成功時のパルス効果 */
.postal-code-success-state {
  animation: successPulse 0.6s ease-in-out;
}

@keyframes successPulse {
  0% { transform: scale(1); }
  50% { transform: scale(1.02); }
  100% { transform: scale(1); }
}

/* エラー時のシェイク効果 */
.postal-code-error-state {
  animation: errorShake 0.5s ease-in-out;
}

@keyframes errorShake {
  0%, 100% { transform: translateX(0); }
  25% { transform: translateX(-5px); }
  75% { transform: translateX(5px); }
}

/* フェードイン効果 */
.postal-code-loading,
.postal-code-error {
  opacity: 0;
  transition: opacity 0.3s ease-in-out;
}

.postal-code-loading.show,
.postal-code-error.show {
  opacity: 1;
}
```

## 高度なカスタマイズ

### 1. カスタムAPIレスポンス処理

```javascript
class CustomPostalCodeAutoFill extends PostalCodeAutoFill {
  constructor(options) {
    super(options);
  }
  
  // カスタムAPIレスポンス解析
  parseApiResponse(response) {
    // 独自APIの場合のレスポンス処理
    if (response.status === 'success' && response.data) {
      return {
        prefecture: response.data.pref_name,
        city: response.data.city_name,
        town: response.data.town_name,
        fullAddress: `${response.data.pref_name}${response.data.city_name}${response.data.town_name}`,
        zipcode: response.data.zip_code,
        prefcode: response.data.pref_code
      };
    }
    return null;
  }
  
  // カスタムバリデーション
  validatePostalCode(postalCode) {
    // 独自のバリデーションロジック
    const cleaned = postalCode.replace(/[^\d-]/g, '');
    
    // 7桁の数字またはXXX-XXXX形式
    if (/^\d{7}$/.test(cleaned) || /^\d{3}-\d{4}$/.test(cleaned)) {
      return cleaned.replace('-', '');
    }
    
    return null;
  }
  
  // カスタムエラーハンドリング
  handleApiError(error, postalCode) {
    console.error('Custom API Error:', error);
    
    // 独自のエラー処理
    if (error.code === 'RATE_LIMIT_EXCEEDED') {
      this.showError('API呼び出し制限に達しました。しばらくお待ちください。');
    } else if (error.code === 'INVALID_POSTAL_CODE') {
      this.showError('郵便番号の形式が正しくありません。');
    } else {
      super.handleApiError(error, postalCode);
    }
  }
}

// 使用例
const customAutoFill = new CustomPostalCodeAutoFill({
  postalCodeSelector: 'input[name="postal_code"]',
  addressSelector: 'textarea[name="address"]',
  apiUrl: 'https://your-api.com/postal-lookup'
});
```

### 2. プラグインシステム

```javascript
// プラグインベースのカスタマイズ
class PostalCodePlugin {
  constructor(name) {
    this.name = name;
  }
  
  beforeInit(autoFillInstance) {
    // 初期化前の処理
  }
  
  afterInit(autoFillInstance) {
    // 初期化後の処理
  }
  
  beforeApiCall(postalCode, autoFillInstance) {
    // API呼び出し前の処理
  }
  
  afterApiCall(addressData, autoFillInstance) {
    // API呼び出し後の処理
  }
}

// 分析プラグイン
class AnalyticsPlugin extends PostalCodePlugin {
  constructor() {
    super('analytics');
  }
  
  afterApiCall(addressData, autoFillInstance) {
    // Google Analytics イベント送信
    if (typeof gtag !== 'undefined') {
      gtag('event', 'postal_code_lookup', {
        event_category: 'form_interaction',
        postal_code: addressData.zipcode,
        prefecture: addressData.prefecture
      });
    }
  }
}

// 拡張されたPostalCodeAutoFillクラス
class ExtendedPostalCodeAutoFill extends PostalCodeAutoFill {
  constructor(options) {
    super(options);
    this.plugins = [];
  }
  
  addPlugin(plugin) {
    this.plugins.push(plugin);
  }
  
  init() {
    this.plugins.forEach(plugin => plugin.beforeInit(this));
    const result = super.init();
    this.plugins.forEach(plugin => plugin.afterInit(this));
    return result;
  }
  
  async fetchAddress(postalCode) {
    this.plugins.forEach(plugin => plugin.beforeApiCall(postalCode, this));
    const result = await super.fetchAddress(postalCode);
    this.plugins.forEach(plugin => plugin.afterApiCall(result, this));
    return result;
  }
}

// 使用例
const extendedAutoFill = new ExtendedPostalCodeAutoFill({
  postalCodeSelector: 'input[name="postal_code"]',
  addressSelector: 'textarea[name="address"]'
});

extendedAutoFill.addPlugin(new AnalyticsPlugin());
extendedAutoFill.init();
```

## 設定プリセット

### 1. 用途別プリセット

```javascript
// プリセット定義
const POSTAL_CODE_PRESETS = {
  // 高速応答重視
  fast: {
    debounceDelay: 200,
    enableCache: true,
    apiTimeout: 3000,
    showLoadingIndicator: false
  },
  
  // 安定性重視
  stable: {
    debounceDelay: 800,
    enableCache: true,
    apiTimeout: 8000,
    showLoadingIndicator: true
  },
  
  // モバイル最適化
  mobile: {
    debounceDelay: 600,
    enableCache: true,
    apiTimeout: 5000,
    showLoadingIndicator: true
  },
  
  // デバッグ用
  debug: {
    debounceDelay: 100,
    enableCache: false,
    apiTimeout: 10000,
    showLoadingIndicator: true
  }
};

// プリセット適用関数
function createPostalCodeAutoFill(preset, customOptions = {}) {
  const presetOptions = POSTAL_CODE_PRESETS[preset] || POSTAL_CODE_PRESETS.stable;
  const options = { ...presetOptions, ...customOptions };
  
  return new PostalCodeAutoFill(options);
}

// 使用例
const fastAutoFill = createPostalCodeAutoFill('fast', {
  postalCodeSelector: '#postal-code',
  addressSelector: '#address'
});

const mobileAutoFill = createPostalCodeAutoFill('mobile', {
  postalCodeSelector: '.mobile-postal-code',
  addressSelector: '.mobile-address'
});
```

### 2. 環境別設定

```javascript
// 環境別設定
const getEnvironmentConfig = () => {
  const isDevelopment = process.env.NODE_ENV === 'development';
  const isProduction = process.env.NODE_ENV === 'production';
  
  if (isDevelopment) {
    return {
      debounceDelay: 100,
      enableCache: false,
      apiTimeout: 10000,
      showLoadingIndicator: true,
      messages: {
        loading: '[DEV] 住所を取得中...',
        invalidFormat: '[DEV] 郵便番号の形式が正しくありません',
        notFound: '[DEV] 該当する住所が見つかりませんでした',
        networkError: '[DEV] 住所の取得に失敗しました',
        timeout: '[DEV] リクエストがタイムアウトしました'
      }
    };
  }
  
  if (isProduction) {
    return {
      debounceDelay: 500,
      enableCache: true,
      apiTimeout: 5000,
      showLoadingIndicator: true
    };
  }
  
  // デフォルト設定
  return {
    debounceDelay: 500,
    enableCache: true,
    apiTimeout: 5000,
    showLoadingIndicator: true
  };
};

// 使用例
const autoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[name="postal_code"]',
  addressSelector: 'textarea[name="address"]',
  ...getEnvironmentConfig()
});
```

## まとめ

郵便番号自動住所入力機能は豊富なカスタマイズオプションを提供し、様々なプロジェクトの要件に対応できます。基本的な設定から高度なカスタマイズまで、プロジェクトのニーズに応じて適切な設定を選択してください。

### カスタマイズのポイント

1. **パフォーマンス**: デバウンス設定とキャッシュ機能でレスポンス性を調整
2. **ユーザビリティ**: ローディング表示とエラーメッセージでユーザー体験を向上
3. **拡張性**: イベントハンドリングとプラグインシステムで機能を拡張
4. **保守性**: プリセットと環境別設定で管理を簡素化

適切なカスタマイズにより、ユーザーにとって最適な住所入力体験を提供できます。