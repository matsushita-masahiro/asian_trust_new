# 購入システム簡素化 - 設計書

## 概要

`customers` テーブルを廃止し、`users` テーブルで購入データを一元管理するシステムに変更します。

## アーキテクチャ

### データベース設計

#### 変更前の構造
```
purchases
├── user_id (仲介者)
├── customer_id (購入者) → customers テーブル参照
└── purchased_at

customers
├── id
├── name
├── email
├── user_id (optional)
└── ...
```

#### 変更後の構造
```
purchases
├── user_id (仲介者)
├── buyer_id (購入者) → users テーブル参照
└── purchased_at

users (既存)
├── id
├── name
├── email
└── ...
```

### マイグレーション戦略

1. **新しいカラムの追加**
   - `purchases` テーブルに `buyer_id` カラムを追加
   - インデックスを設定

2. **データ移行**
   - 既存の `customers` データを `users` テーブルに移行
   - `purchases.customer_id` を `purchases.buyer_id` に変換

3. **古いカラムの削除**
   - `purchases.customer_id` カラムを削除
   - `customers` テーブルを削除

## コンポーネント設計

### モデルの変更

#### Purchase モデル
```ruby
class Purchase < ApplicationRecord
  belongs_to :user      # 仲介者
  belongs_to :buyer, class_name: 'User'  # 購入者
  has_many :purchase_items, dependent: :destroy
  
  # 自分の購入履歴
  scope :bought_by, ->(user) { where(buyer_id: user.id) }
  
  # 自分が仲介した販売履歴（自分の購入は除外）
  scope :sold_by, ->(user) { where(user_id: user.id).where.not(buyer_id: user.id) }
end
```

#### User モデル
```ruby
class User < ApplicationRecord
  # 仲介した購入
  has_many :mediated_purchases, class_name: 'Purchase', foreign_key: 'user_id'
  
  # 自分の購入
  has_many :purchases, class_name: 'Purchase', foreign_key: 'buyer_id'
  
  # 自分の購入履歴の合計金額
  def own_purchase_total(month)
    purchases.in_month_tokyo(month).sum(&:total_price)
  end
  
  # 販売履歴の合計金額（自分の購入は除外）
  def sales_total(month)
    mediated_purchases.where.not(buyer_id: id).in_month_tokyo(month).sum(&:total_price)
  end
end
```

### コントローラーの変更

#### UsersController#purchases
```ruby
def purchases
  if params[:view] == 'own_purchases'
    # 自分の購入履歴
    @purchases = Purchase.bought_by(@user).in_month_tokyo(@selected_month)
    @is_own_purchases = true
  else
    # 販売履歴（自分の購入は除外）
    @purchases = Purchase.sold_by(@user).in_month_tokyo(@selected_month)
    @is_own_purchases = false
  end
end
```

### ビューの変更

#### 購入履歴表示
- 購入者情報として自分の名前を表示
- 「購入履歴」タイトルを使用

#### 販売履歴表示
- 購入者情報として実際の購入者名を表示
- 「販売履歴」タイトルを使用

## データ移行設計

### ステップ1: スキーマ変更
```ruby
class AddBuyerIdToPurchases < ActiveRecord::Migration[8.0]
  def change
    add_column :purchases, :buyer_id, :integer
    add_index :purchases, :buyer_id
    add_index :purchases, [:user_id, :buyer_id]
    add_foreign_key :purchases, :users, column: :buyer_id
  end
end
```

### ステップ2: データ移行
```ruby
class MigrateCustomersToUsers < ActiveRecord::Migration[8.0]
  def up
    Purchase.includes(:customer).find_each do |purchase|
      customer = purchase.customer
      next unless customer
      
      if customer.user_id.present?
        # 既存のユーザーIDを使用
        purchase.update!(buyer_id: customer.user_id)
      else
        # 新しいユーザーを作成
        user = User.create!(
          name: customer.name,
          email: customer.email || "customer_#{customer.id}@example.com",
          password: SecureRandom.hex(16),
          level_id: Level.find_by(value: 6)&.id # お客様レベル
        )
        purchase.update!(buyer_id: user.id)
      end
    end
  end
end
```

### ステップ3: 古いスキーマ削除
```ruby
class RemoveCustomerReferences < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :purchases, :customers
    remove_column :purchases, :customer_id
    drop_table :customers
  end
end
```

## エラーハンドリング

### データ整合性チェック
- 移行前に `purchases` と `customers` の関連性を検証
- 移行後に `buyer_id` が正しく設定されているかを確認

### ロールバック対応
- 各マイグレーションステップでロールバック可能な設計
- データバックアップの推奨

## テスト戦略

### 単体テスト
- Purchase モデルの新しいスコープ
- User モデルの新しいメソッド

### 統合テスト
- 購入履歴表示の正確性
- 販売履歴表示の正確性
- データ移行の完全性

### パフォーマンステスト
- 新しいインデックスの効果確認
- クエリ実行時間の測定

## セキュリティ考慮事項

### アクセス制御
- 購入履歴は本人のみ閲覧可能
- 販売履歴は仲介者のみ閲覧可能

### データプライバシー
- 移行時の個人情報保護
- 不要なデータの適切な削除