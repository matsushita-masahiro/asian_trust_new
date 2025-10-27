# 郵便番号自動住所入力機能 設計文書

## Overview

ユーザーが住所登録フォームで郵便番号を入力すると、外部APIを使用して自動的に都道府県・市区町村・町域の住所情報を取得し、住所フィールドに反映する機能を実装する。この機能は既存のusers/showページの住所入力フォームに統合され、将来的に他のフォームでも再利用可能な設計とする。

## Architecture

### システム構成
```
Frontend (JavaScript)
├── PostalCodeAutoFill クラス
├── API通信モジュール
└── フォーム統合モジュール

External API
├── zipcloud API (Primary)
└── フォールバック機能

Backend (Rails)
├── 既存のAddress モデル
├── 既存のUsers コントローラー
└── 既存のAddresses コントローラー
```

### データフロー
1. ユーザーが郵便番号を入力
2. JavaScript が入力を検知（7桁完了時）
3. 外部API（zipcloud）に郵便番号を送信
4. APIレスポンスを受信・パース
5. 住所フィールドに自動入力
6. エラー時は適切なメッセージを表示

## Components and Interfaces

### 1. PostalCodeAutoFill JavaScript クラス

```javascript
class PostalCodeAutoFill {
  constructor(options = {}) {
    this.postalCodeSelector = options.postalCodeSelector || 'input[name*="postal_code"]';
    this.addressSelector = options.addressSelector || 'textarea[name*="address"]';
    this.apiUrl = 'https://zipcloud.ibsnet.co.jp/api/search';
    this.cache = new Map();
    this.debounceTimer = null;
    this.loadingIndicator = null;
  }

  // 初期化メソッド
  init() { /* ... */ }
  
  // 郵便番号入力イベントハンドラー
  handlePostalCodeInput(event) { /* ... */ }
  
  // API呼び出しメソッド
  async fetchAddress(postalCode) { /* ... */ }
  
  // 住所フィールド更新メソッド
  updateAddressField(addressData) { /* ... */ }
  
  // エラーハンドリング
  showError(message) { /* ... */ }
  
  // ローディング表示制御
  showLoading() { /* ... */ }
  hideLoading() { /* ... */ }
}
```

### 2. API統合モジュール

#### zipcloud API仕様
- **エンドポイント**: `https://zipcloud.ibsnet.co.jp/api/search`
- **パラメータ**: `zipcode` (郵便番号、ハイフンなし)
- **レスポンス形式**: JSON
```json
{
  "message": null,
  "results": [
    {
      "zipcode": "1234567",
      "prefcode": "13",
      "address1": "東京都",
      "address2": "新宿区",
      "address3": "西新宿",
      "kana1": "トウキョウト",
      "kana2": "シンジュクク",
      "kana3": "ニシシンジュク"
    }
  ],
  "status": 200
}
```

### 3. フォーム統合

#### 既存フォーム構造との統合
- 郵便番号フィールド: `input[name*="postal_code"]`
- 住所フィールド: `textarea[name*="address"]`
- 登録住所・配送先住所の両方に対応

#### HTML構造の拡張
```html
<!-- ローディングインジケーター -->
<div class="postal-code-loading" style="display: none;">
  <small class="text-muted">
    <i class="fas fa-spinner fa-spin"></i> 住所を取得中...
  </small>
</div>

<!-- エラーメッセージ -->
<div class="postal-code-error" style="display: none;">
  <small class="text-danger">
    <i class="fas fa-exclamation-triangle"></i> 
    <span class="error-message"></span>
  </small>
</div>
```

## Data Models

### 既存モデルとの関係
- **Address モデル**: 既存のモデルを使用、変更なし
- **User モデル**: 既存のモデルを使用、変更なし

### APIレスポンスデータ構造
```javascript
// zipcloud APIレスポンス
interface ZipcloudResponse {
  message: string | null;
  results: Array<{
    zipcode: string;
    prefcode: string;
    address1: string; // 都道府県
    address2: string; // 市区町村
    address3: string; // 町域
    kana1: string;
    kana2: string;
    kana3: string;
  }>;
  status: number;
}

// 内部使用データ構造
interface AddressData {
  prefecture: string;
  city: string;
  town: string;
  fullAddress: string;
}
```

## Error Handling

### エラーケースと対応

1. **無効な郵便番号**
   - 7桁未満または数字以外が含まれる場合
   - メッセージ: "正しい郵便番号を入力してください（例: 123-4567）"

2. **郵便番号が見つからない**
   - APIが該当する住所を返さない場合
   - メッセージ: "該当する住所が見つかりませんでした"

3. **API通信エラー**
   - ネットワークエラー、タイムアウト等
   - メッセージ: "住所の取得に失敗しました。手動で入力してください"

4. **APIレート制限**
   - 短時間での連続リクエスト制限
   - デバウンス機能で制御（500ms）

### エラー表示方法
- 郵便番号フィールドの下に小さなエラーメッセージを表示
- 赤色のアイコンと文字で視覚的に分かりやすく表示
- エラー解消時は自動的にメッセージを非表示

## Testing Strategy

### 単体テスト
1. **PostalCodeAutoFill クラス**
   - 郵便番号フォーマット検証
   - API呼び出し機能
   - 住所フィールド更新機能
   - エラーハンドリング

2. **API統合**
   - 正常なAPIレスポンス処理
   - エラーレスポンス処理
   - ネットワークエラー処理

### 統合テスト
1. **フォーム統合**
   - users/showページでの動作確認
   - 登録住所・配送先住所両方での動作
   - Turboフレームワークとの互換性

2. **ユーザビリティテスト**
   - 実際の郵便番号での住所取得
   - 手動編集との併用
   - レスポンシブデザインでの動作

### テストデータ
```javascript
// テスト用郵便番号
const testPostalCodes = {
  valid: '1000001',      // 東京都千代田区千代田
  invalid: '0000000',    // 存在しない郵便番号
  malformed: '123-abc'   // 不正な形式
};
```

## Implementation Details

### ファイル構成
```
app/javascript/
├── postal_code_auto_fill.js  # メインクラス
└── application.js             # 統合・初期化

app/views/users/
└── show.html.erb              # フォーム統合

app/assets/stylesheets/
└── postal_code_auto_fill.scss # スタイル定義
```

### 初期化フロー
1. `application.js` で PostalCodeAutoFill をインポート
2. DOMContentLoaded および turbo:load イベントで初期化
3. 各住所フォームに対してインスタンスを作成
4. イベントリスナーを設定

### パフォーマンス最適化
1. **デバウンス機能**: 500ms の遅延で API 呼び出しを制御
2. **キャッシュ機能**: 同じ郵便番号の結果をメモリにキャッシュ
3. **非同期処理**: async/await を使用してUIブロックを防止

### セキュリティ考慮事項
1. **HTTPS通信**: 外部APIとの通信は必ずHTTPS
2. **入力サニタイゼーション**: 郵便番号入力の数字以外を除去
3. **XSS対策**: DOM操作時のエスケープ処理

### ブラウザ互換性
- モダンブラウザ（Chrome, Firefox, Safari, Edge）
- ES6+ 機能を使用（async/await, Map, class）
- IE11 は対象外

## Integration Points

### 既存システムとの統合
1. **Turbo フレームワーク**: turbo:load イベントでの再初期化
2. **Bootstrap**: 既存のフォームスタイルとの調和
3. **Rails UJS**: 既存のフォーム送信機能との共存

### 将来の拡張性
1. **他フォームでの利用**: セレクター設定で他のページでも利用可能
2. **API切り替え**: 設定変更で他の郵便番号APIに対応可能
3. **国際化**: 将来的に他国の郵便番号システムに対応可能

### 設定オプション
```javascript
// カスタマイズ可能な設定
const options = {
  postalCodeSelector: 'input[name*="postal_code"]',
  addressSelector: 'textarea[name*="address"]',
  debounceDelay: 500,
  enableCache: true,
  showLoadingIndicator: true,
  apiTimeout: 5000
};
```