# ユーザー住所管理機能 設計書

## Overview

ユーザーの複数住所管理を実現するため、独立したAddressモデルを作成し、既存システムとの互換性を保ちながら拡張可能な住所管理システムを構築する。

## Architecture

### システム構成
```
User (1) ←→ (N) Address
- has_many :addresses
- has_one :registration_address
- has_one :shipping_address
```

### データフロー
1. ユーザーが住所情報を登録/更新
2. Addressモデルでバリデーション実行
3. 既存住所の場合は更新、新規の場合は作成
4. 既存システムの互換性メソッドで住所情報を提供

## Components and Interfaces

### 1. Addressモデル
```ruby
class Address < ApplicationRecord
  belongs_to :user
  
  # 住所タイプの定義（将来的な拡張を考慮）
  enum address_type: {
    registration: 'registration',  # 登録住所（請求先住所）
    shipping: 'shipping'           # 配送先住所
    # 将来追加可能: company: 'company', emergency: 'emergency' など
  }
  
  # 住所タイプの表示名
  def self.address_type_labels
    {
      'registration' => '登録住所',
      'shipping' => '配送先住所'
    }
  end
  
  def address_type_label
    self.class.address_type_labels[address_type] || address_type
  end
  
  validates :user_id, :address_type, :address, presence: true
  validates :address_type, uniqueness: { scope: :user_id }
  validates :postal_code, format: { with: /\A\d{3}-\d{4}\z/ }, allow_blank: true
  
  before_save :format_postal_code
  
  private
  
  def format_postal_code
    if postal_code.present?
      # ハイフンなしの場合はハイフンを追加
      self.postal_code = postal_code.gsub(/\D/, '').gsub(/(\d{3})(\d{4})/, '\1-\2')
    end
  end
end
```

### 2. Userモデル拡張
```ruby
class User < ApplicationRecord
  has_many :addresses, dependent: :destroy
  has_one :registration_address, -> { where(address_type: 'registration') }, class_name: 'Address'
  has_one :shipping_address, -> { where(address_type: 'shipping') }, class_name: 'Address'
  
  # 後方互換性メソッド
  def primary_address
    registration_address&.full_address || invoice_base&.address
  end
end
```

### 3. コントローラー
- `UsersController`: users/showでの住所表示・更新
- `AddressesController`: 住所のCRUD操作（Ajax対応）
- `Admin::AddressesController`: 管理者用住所管理

### 4. ビュー
- `users/show`: ユーザー詳細画面での住所登録/編集
- 住所登録/編集フォーム（モーダルまたはインライン）
- 管理画面での住所表示
- 既存画面での住所表示（互換性維持）

## Data Models

### Addressesテーブル
```sql
CREATE TABLE addresses (
  id BIGINT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  address_type VARCHAR(50) NOT NULL,
  postal_code VARCHAR(10),
  address TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  deleted_at TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id),
  UNIQUE KEY unique_user_address_type (user_id, address_type)
);
```

### インデックス
- `user_id, address_type` (ユニーク)
- `user_id` (検索用)
- `address_type` (タイプ別検索用)

## Error Handling

### バリデーションエラー
- 必須項目未入力: `address_type`, `address`
- 重複住所タイプ: 既存住所を更新
- 郵便番号形式エラー: フォーマット警告表示
- 郵便番号自動フォーマット: 入力時にハイフンを自動追加

### システムエラー
- データベース接続エラー: 適切なエラーメッセージ表示
- 権限エラー: アクセス拒否メッセージ

## Testing Strategy

### 1. モデルテスト
- Addressモデルのバリデーション
- User-Address関連のテスト
- 後方互換性メソッドのテスト

### 2. コントローラーテスト
- 住所CRUD操作
- 権限チェック
- エラーハンドリング

### 3. 統合テスト
- 住所登録フロー
- 管理画面での住所管理
- 既存機能との互換性

### 4. マイグレーションテスト
- 既存データの移行
- ロールバック機能

## Migration Strategy

### Phase 1: モデル作成
1. Addressモデル作成
2. マイグレーション実行
3. Userモデル関連追加

### Phase 2: データ移行
1. 既存invoice_baseデータをAddressに移行
2. 後方互換性メソッド実装
3. 既存機能の動作確認

### Phase 3: UI実装
1. users/showページに住所登録/編集機能追加
2. 住所管理用のAjaxフォーム実装
3. 管理者画面更新
4. 既存画面の住所表示更新

## Security Considerations

### データ保護
- 住所情報のサニタイゼーション
- XSS対策
- SQLインジェクション対策

### アクセス制御
- ユーザーは自分の住所のみ操作可能
- 管理者は全ユーザーの住所を管理可能
- 適切な権限チェック

### 監査ログ
- 住所変更履歴の記録
- 管理者操作ログ
- セキュリティイベントの追跡

## Performance Considerations

### データベース最適化
- 適切なインデックス設定
- N+1クエリ対策
- キャッシュ戦略

### メモリ使用量
- 大量住所データの効率的な処理
- ページネーション実装

## Backward Compatibility

### 既存メソッド維持
- `user.invoice_base.address` → `user.primary_address`
- 既存ビューでの住所表示継続
- API互換性維持

### 段階的移行
1. 新システム並行稼働
2. 既存システムから新システムへの参照切り替え
3. 旧システム段階的廃止
##
 User Interface Design

### users/showページでの住所管理

#### 表示レイアウト
```
基本情報カード
├── 既存の基本情報
└── 住所情報セクション
    ├── 登録住所
    │   ├── 表示エリア（住所が登録済みの場合）
    │   └── [編集]ボタン
    └── 配送先住所
        ├── 表示エリア（住所が登録済みの場合）
        └── [編集]ボタン
```

#### 編集フォーム
- インライン編集またはモーダル形式
- 郵便番号、住所の入力フィールド
- 郵便番号は入力時に自動的にハイフン付きフォーマットで保存
- [保存][キャンセル]ボタン
- Ajax による非同期更新

#### 権限制御
- 自分の住所のみ編集可能
- 管理者は全ユーザーの住所を編集可能## Addr
ess Type Management

### 現在サポートする住所タイプ
- `registration`: 登録住所（請求先住所）
- `shipping`: 配送先住所

### 将来追加可能な住所タイプ例
- `company`: 会社住所
- `emergency`: 緊急連絡先住所
- `temporary`: 一時的な住所

### 住所タイプの追加方法
1. `Address.rb`のenumに新しいタイプを追加
2. `address_type_labels`メソッドに表示名を追加
3. 必要に応じてUserモデルに関連メソッドを追加
4. UIで新しい住所タイプに対応

### 住所タイプの制約
- 各ユーザーは各住所タイプにつき1つの住所のみ登録可能
- 住所タイプは必須項目
- 住所タイプの変更は既存住所の更新として処理