# 郵便番号自動住所入力機能 技術仕様書

## アーキテクチャ概要

### システム構成

```
Frontend (JavaScript)
├── PostalCodeAutoFill クラス
│   ├── 入力検知・バリデーション
│   ├── API通信管理
│   ├── キャッシュ管理
│   ├── UI状態管理
│   └── イベント管理
├── UI要素管理
│   ├── ローディングインジケーター
│   ├── エラー表示
│   └── 視覚的フィードバック
└── イベントシステム
    ├── カスタムイベント発火
    └── DOM イベントハンドリング

External API
└── zipcloud API
    ├── 郵便番号検索
    └── 住所データ取得

Backend Integration
├── Rails フォーム統合
├── Address モデル連携
└── バリデーション連携
```

## クラス設計

### PostalCodeAutoFill クラス

#### コンストラクター

```javascript
constructor(options = {})
```

**パラメーター:**
- `options.postalCodeSelector` (string): 郵便番号フィールドセレクター
- `options.addressSelector` (string): 住所フィールドセレクター  
- `options.apiUrl` (string): API エンドポイント URL
- `options.debounceDelay` (number): デバウンス遅延時間（ms）
- `options.enableCache` (boolean): キャッシュ機能有効化
- `options.showLoadingIndicator` (boolean): ローディング表示有効化
- `options.apiTimeout` (number): API タイムアウト時間（ms）

#### 主要メソッド

##### 初期化・設定

```javascript
init(): boolean
```
- DOM要素の取得とイベントリスナー設定
- UI要素の作成
- アクセシビリティ対応の設定
- 戻り値: 初期化成功時 true

```javascript
destroy(): void
```
- イベントリスナーの削除
- UI要素のクリーンアップ
- タイマーの停止
- メモリリークの防止

##### 郵便番号処理

```javascript
validateAndFormatPostalCode(input: string): string|null
```
- 郵便番号の形式検証
- ハイフンあり/なし両対応
- 戻り値: フォーマット済み郵便番号または null

```javascript
async fetchAddress(postalCode: string): Promise<Object|null>
```
- zipcloud API への HTTP リクエスト
- タイムアウト制御
- エラーハンドリング
- 戻り値: 住所データまたは null

##### 住所更新

```javascript
updateAddressField(addressData: Object): void
```
- 住所フィールドの自動更新
- 手動編集状態の考慮
- 視覚的フィードバックの提供

```javascript
updateAddressPreservingUserIntent(addressData: Object): void
```
- ユーザーの手動編集内容を保持した住所更新
- 詳細情報の保持

##### キャッシュ管理

```javascript
getCachedAddress(postalCode: string): Object|null
```
- キャッシュからの住所データ取得
- 有効期限チェック
- LRU アクセス時刻更新

```javascript
setCachedAddress(postalCode: string, addressData: Object): void
```
- 住所データのキャッシュ保存
- サイズ制限管理
- 古いエントリの削除

```javascript
getCacheStats(): Object
```
- キャッシュ統計情報の取得
- ヒット率計算
- メモリ使用量監視

##### API制限管理

```javascript
isApiCallAllowed(): boolean
```
- API呼び出し制限チェック
- レート制限の実装
- 戻り値: 呼び出し許可状態

```javascript
getApiCallStats(): Object
```
- API呼び出し統計の取得
- 残り呼び出し回数の計算

##### 手動編集管理

```javascript
handleAddressManualEdit(event: Event): void
```
- 手動編集の検知
- 編集履歴の記録
- 視覚的インジケーターの表示

```javascript
shouldOverrideManualEdit(): boolean
```
- 手動編集後の自動上書き制御
- 時間経過による制御
- ユーザー意図の保持

## データ構造

### 住所データ形式

```javascript
interface AddressData {
  prefecture: string;      // 都道府県
  city: string;           // 市区町村
  town: string;           // 町域
  fullAddress: string;    // 完全な住所文字列
  zipcode: string;        // 郵便番号
  prefcode: string;       // 都道府県コード
  kana: {                 // 読み仮名
    prefecture: string;
    city: string;
    town: string;
  }
}
```

### キャッシュエントリ形式

```javascript
interface CacheEntry {
  data: AddressData;      // 住所データ
  timestamp: number;      // 作成時刻
  lastAccessed: number;   // 最終アクセス時刻
  postalCode: string;     // 郵便番号
}
```

### 設定オブジェクト形式

```javascript
interface Config {
  postalCodeSelector: string;
  addressSelector: string;
  apiUrl: string;
  debounceDelay: number;
  enableCache: boolean;
  showLoadingIndicator: boolean;
  apiTimeout: number;
}
```

## API仕様

### zipcloud API

#### エンドポイント
```
GET https://zipcloud.ibsnet.co.jp/api/search?zipcode={郵便番号}
```

#### リクエストパラメーター
- `zipcode` (string, required): 7桁の郵便番号（ハイフンなし）

#### レスポンス形式

**成功時:**
```json
{
  "message": null,
  "results": [
    {
      "zipcode": "1000001",
      "prefcode": "13",
      "address1": "東京都",
      "address2": "千代田区",
      "address3": "千代田",
      "kana1": "トウキョウト",
      "kana2": "チヨダク",
      "kana3": "チヨダ"
    }
  ],
  "status": 200
}
```

**エラー時:**
```json
{
  "message": "該当するデータが見つかりません。",
  "results": null,
  "status": 400
}
```

## イベントシステム

### カスタムイベント

#### postalCodeAutoFill:addressUpdated

住所が自動更新された時に発火

```javascript
event.detail = {
  addressData: AddressData,
  postalCodeField: HTMLElement,
  addressField: HTMLElement
}
```

#### postalCodeAutoFill:manualEdit

住所が手動編集された時に発火

```javascript
event.detail = {
  originalValue: string,
  editedValue: string,
  editHistory: Array<EditHistoryEntry>,
  addressField: HTMLElement
}
```

### DOM イベント

- `input`: 郵便番号フィールドの入力検知
- `focus`: フィールドフォーカス時の処理
- `blur`: フィールドフォーカス離脱時の処理

## パフォーマンス仕様

### レスポンス時間目標

- **キャッシュヒット時**: < 50ms
- **API呼び出し時**: < 2000ms
- **デバウンス遅延**: 500ms（設定可能）

### メモリ使用量制限

- **キャッシュサイズ**: 最大100エントリ
- **キャッシュ有効期限**: 30分
- **API呼び出し履歴**: 最大60エントリ

### API制限

- **呼び出し頻度**: 1分間に30回まで
- **タイムアウト**: 5秒（設定可能）
- **同時リクエスト**: 制限なし（ブラウザ制限に依存）

## エラーハンドリング

### エラー分類

#### バリデーションエラー
- 郵便番号形式不正
- 必須フィールド未入力
- 文字数制限超過

#### API エラー
- ネットワークエラー
- タイムアウトエラー
- レスポンス形式エラー
- レート制限エラー

#### システムエラー
- DOM要素未発見
- JavaScript実行エラー
- メモリ不足

### エラーメッセージ

```javascript
const ERROR_MESSAGES = {
  INVALID_FORMAT: '郵便番号の形式が正しくありません（例: 123-4567）',
  NOT_FOUND: '該当する住所が見つかりませんでした',
  NETWORK_ERROR: '住所の取得に失敗しました。手動で入力してください',
  TIMEOUT: 'APIリクエストがタイムアウトしました',
  RATE_LIMIT: 'API呼び出し制限に達しました。しばらくお待ちください',
  TOO_LONG: '郵便番号は7桁以内で入力してください',
  NUMBERS_ONLY: '郵便番号は数字のみで入力してください'
};
```

## セキュリティ仕様

### 入力サニタイゼーション

```javascript
// 郵便番号の清浄化
function sanitizePostalCode(input) {
  return input.replace(/[^\d-]/g, ''); // 数字とハイフンのみ許可
}
```

### XSS対策

- DOM操作時の適切なエスケープ
- innerHTML の使用制限
- textContent の優先使用

### HTTPS通信

- 外部API通信は必ずHTTPS
- Mixed Content の防止

## ブラウザ互換性

### サポート対象

- **Chrome**: 60+
- **Firefox**: 55+
- **Safari**: 12+
- **Edge**: 79+

### 必要なJavaScript機能

- ES6 Classes
- async/await
- fetch API
- Promise
- Map
- CustomEvent
- addEventListener

### ポリフィル対応

IE11などの古いブラウザは対象外ですが、必要に応じて以下のポリフィルを追加可能：

```javascript
// fetch polyfill
if (!window.fetch) {
  // fetch polyfill を読み込み
}

// Promise polyfill
if (!window.Promise) {
  // Promise polyfill を読み込み
}
```

## テスト仕様

### テストカバレッジ目標

- **単体テスト**: 80%以上
- **統合テスト**: 主要フロー100%
- **システムテスト**: 全ブラウザ対応

### テストケース分類

#### 機能テスト
- 郵便番号入力→住所自動取得
- エラーハンドリング
- 手動編集機能
- キャッシュ機能

#### パフォーマンステスト
- レスポンス時間測定
- メモリ使用量監視
- API呼び出し制限テスト

#### 互換性テスト
- 複数ブラウザでの動作確認
- レスポンシブデザイン対応
- Turbo フレームワーク互換性

## デプロイメント

### ファイル構成

```
app/javascript/
├── postal_code_auto_fill.js    # メインクラス
└── application.js               # 初期化コード

app/assets/stylesheets/
└── postal_code_auto_fill.scss   # スタイル定義

app/views/
└── users/show.html.erb          # フォーム統合

docs/
├── postal_code_auto_fill_usage.md
└── postal_code_auto_fill_technical_spec.md
```

### ビルド要件

- **Rails**: 7.0+
- **Node.js**: 16+
- **importmap-rails**: JavaScript モジュール管理

### 環境変数

現在、環境変数による設定は不要ですが、将来的に以下の設定を追加可能：

```bash
POSTAL_CODE_API_URL=https://zipcloud.ibsnet.co.jp/api/search
POSTAL_CODE_API_TIMEOUT=5000
POSTAL_CODE_CACHE_ENABLED=true
```

## 監視・ログ

### ログ出力

```javascript
// 開発環境でのデバッグログ
console.log('PostalCodeAutoFill: 初期化完了');
console.log('PostalCodeAutoFill: API呼び出し開始', { postalCode });
console.warn('PostalCodeAutoFill: API呼び出し制限により処理をスキップ');
console.error('PostalCodeAutoFill: API呼び出しエラー', { error });
```

### メトリクス収集

```javascript
// パフォーマンスメトリクス
const metrics = {
  apiCallCount: 0,
  cacheHitCount: 0,
  errorCount: 0,
  averageResponseTime: 0
};
```

## 今後の拡張予定

### Phase 2 機能

1. **国際化対応**
   - 多言語エラーメッセージ
   - 海外住所形式対応

2. **高度なキャッシュ機能**
   - LocalStorage 永続化
   - キャッシュ同期機能

3. **分析機能**
   - 使用統計の収集
   - パフォーマンス分析

4. **カスタマイズ機能**
   - テーマ対応
   - アニメーション設定

### API拡張

1. **複数API対応**
   - フォールバック API
   - API選択機能

2. **住所補完機能**
   - 部分住所からの補完
   - 住所候補表示

## 変更履歴

### v1.0.0 (2024-XX-XX)
- 初回リリース
- 基本的な郵便番号自動入力機能
- キャッシュ機能
- エラーハンドリング
- 手動編集対応
- Turbo対応
- 包括的なテストスイート