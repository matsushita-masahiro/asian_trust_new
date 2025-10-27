# 郵便番号自動住所入力機能

日本の郵便番号を入力すると自動的に住所を取得して入力フィールドに反映するJavaScript機能です。

## 特徴

- 🚀 **高速レスポンス**: デバウンス機能とキャッシュによる最適化
- 🎯 **高精度**: zipcloud APIによる正確な住所データ
- 🔧 **カスタマイズ可能**: 豊富な設定オプション
- 📱 **レスポンシブ対応**: モバイルデバイスでも快適に動作
- ♿ **アクセシビリティ**: ARIA属性による支援技術対応
- 🔄 **Turbo対応**: Rails Turboフレームワークと完全互換
- ✋ **手動編集対応**: 自動入力後の手動編集を適切に処理

## デモ

![郵便番号自動入力デモ](demo.gif)

## クイックスタート

### 1. 基本的な使用方法

```html
<!-- HTML -->
<input type="text" id="postal-code" placeholder="例: 123-4567">
<textarea id="address" placeholder="住所が自動入力されます"></textarea>
```

```javascript
// JavaScript
import PostalCodeAutoFill from './postal_code_auto_fill.js';

const autoFill = new PostalCodeAutoFill({
  postalCodeSelector: '#postal-code',
  addressSelector: '#address'
});
autoFill.init();
```

### 2. Rails フォームでの使用

```erb
<!-- app/views/users/show.html.erb -->
<%= form_with model: @user do |f| %>
  <%= f.text_field :postal_code, 
      class: "form-control postal-code-input",
      placeholder: "例: 123-4567" %>
  
  <%= f.text_area :address, 
      class: "form-control address-input",
      placeholder: "住所が自動入力されます" %>
<% end %>
```

## インストール

### Rails プロジェクトの場合

1. JavaScriptファイルを配置:
```bash
# app/javascript/postal_code_auto_fill.js をコピー
```

2. application.js に追加:
```javascript
import PostalCodeAutoFill from './postal_code_auto_fill.js';

document.addEventListener('DOMContentLoaded', initializePostalCodeAutoFill);
document.addEventListener('turbo:load', initializePostalCodeAutoFill);

function initializePostalCodeAutoFill() {
  const autoFill = new PostalCodeAutoFill();
  autoFill.init();
}
```

3. スタイルシートを追加:
```scss
// app/assets/stylesheets/postal_code_auto_fill.scss をインポート
@import "postal_code_auto_fill";
```

## 設定オプション

```javascript
const autoFill = new PostalCodeAutoFill({
  // 郵便番号フィールドのセレクター
  postalCodeSelector: 'input[name*="postal_code"]',
  
  // 住所フィールドのセレクター
  addressSelector: 'textarea[name*="address"]',
  
  // デバウンス遅延時間（ミリ秒）
  debounceDelay: 500,
  
  // キャッシュ機能の有効/無効
  enableCache: true,
  
  // ローディング表示の有効/無効
  showLoadingIndicator: true,
  
  // APIタイムアウト時間（ミリ秒）
  apiTimeout: 5000
});
```

## 使用例

### 基本的な使用例

```javascript
// 最小限の設定
const autoFill = new PostalCodeAutoFill({
  postalCodeSelector: '#postal-code',
  addressSelector: '#address'
});
autoFill.init();
```

### 複数フォームでの使用

```javascript
// 請求先住所
const billingAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[data-type="billing"][name="postal_code"]',
  addressSelector: 'textarea[data-type="billing"][name="address"]'
});
billingAutoFill.init();

// 配送先住所
const shippingAutoFill = new PostalCodeAutoFill({
  postalCodeSelector: 'input[data-type="shipping"][name="postal_code"]',
  addressSelector: 'textarea[data-type="shipping"][name="address"]'
});
shippingAutoFill.init();
```

### カスタムイベントの活用

```javascript
// 住所更新時の処理
document.addEventListener('postalCodeAutoFill:addressUpdated', function(event) {
  console.log('住所が更新されました:', event.detail.addressData);
  
  // 都道府県フィールドを自動設定
  const prefectureField = document.querySelector('#prefecture');
  if (prefectureField) {
    prefectureField.value = event.detail.addressData.prefecture;
  }
});

// 手動編集時の処理
document.addEventListener('postalCodeAutoFill:manualEdit', function(event) {
  console.log('住所が手動編集されました');
  // カスタム処理を追加
});
```

## API

### メソッド

| メソッド | 説明 | 戻り値 |
|---------|------|--------|
| `init()` | 機能を初期化 | `boolean` |
| `destroy()` | 機能を無効化・クリーンアップ | `void` |
| `getCacheStats()` | キャッシュ統計を取得 | `Object` |
| `getApiCallStats()` | API呼び出し統計を取得 | `Object` |

### イベント

| イベント名 | 発火タイミング | detail |
|-----------|---------------|--------|
| `postalCodeAutoFill:addressUpdated` | 住所が自動更新された時 | `{addressData, postalCodeField, addressField}` |
| `postalCodeAutoFill:manualEdit` | 住所が手動編集された時 | `{originalValue, editedValue, editHistory, addressField}` |

## 対応ブラウザ

- Chrome 60+
- Firefox 55+
- Safari 12+
- Edge 79+

## 依存関係

- **必須**: なし（Vanilla JavaScript）
- **推奨**: Bootstrap 5（スタイリング用）

## パフォーマンス

- **初回取得**: ~1-2秒（API呼び出し）
- **キャッシュヒット**: ~50ms
- **メモリ使用量**: ~1MB（100件キャッシュ時）
- **API制限**: 1分間に30回まで

## セキュリティ

- HTTPS通信のみ
- 入力値のサニタイゼーション
- XSS対策済み

## テスト

```bash
# 統合テスト実行
rails test test/integration/postal_code_auto_fill_integration_test.rb

# システムテスト実行
rails test test/system/postal_code_auto_fill_test.rb

# エラーハンドリングテスト実行
rails test test/system/postal_code_error_handling_test.rb

# パフォーマンステスト実行
rails test test/system/postal_code_performance_test.rb
```

## トラブルシューティング

### よくある問題

**Q: 住所が自動入力されない**
A: 以下を確認してください：
- 郵便番号が7桁の数字であること
- セレクターが正しく設定されていること
- ネットワーク接続が正常であること

**Q: エラーメッセージが表示される**
A: エラーメッセージの内容に応じて対処してください：
- 「正しい郵便番号を入力してください」→ 7桁の数字で入力
- 「該当する住所が見つかりませんでした」→ 存在する郵便番号を入力
- 「住所の取得に失敗しました」→ ネットワーク接続を確認

**Q: Turboで動作しない**
A: `turbo:load` イベントでも初期化を行ってください：

```javascript
document.addEventListener('turbo:load', function() {
  initializePostalCodeAutoFill();
});
```

### デバッグ方法

```javascript
// デバッグモードで初期化
const autoFill = new PostalCodeAutoFill({
  postalCodeSelector: '#postal-code',
  addressSelector: '#address'
});

// 初期化結果を確認
if (autoFill.init()) {
  console.log('初期化成功');
} else {
  console.error('初期化失敗');
}

// 統計情報を確認
console.log('キャッシュ統計:', autoFill.getCacheStats());
console.log('API統計:', autoFill.getApiCallStats());
```

## ライセンス

MIT License

## 貢献

プルリクエストやIssueの報告を歓迎します。

### 開発環境のセットアップ

```bash
# リポジトリをクローン
git clone [repository-url]

# 依存関係をインストール
bundle install
npm install

# テストを実行
rails test

# 開発サーバーを起動
rails server
```

## 更新履歴

### v1.0.0 (2024-XX-XX)
- 初回リリース
- 基本的な郵便番号自動入力機能
- キャッシュ機能
- エラーハンドリング
- 手動編集対応
- Turbo対応

## サポート

- 📧 Email: [support-email]
- 🐛 Issues: [GitHub Issues URL]
- 📖 Documentation: [Documentation URL]

## 関連リンク

- [使用方法ガイド](postal_code_auto_fill_usage.md)
- [技術仕様書](postal_code_auto_fill_technical_spec.md)
- [zipcloud API](https://zipcloud.ibsnet.co.jp/)

---

Made with ❤️ for better user experience