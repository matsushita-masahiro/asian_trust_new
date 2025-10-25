# WOTT Level Management System Design

## Overview

WOTT商品販売用の独立したレベル管理システムを設計します。既存の上清液レベルシステムと並行して動作し、ユーザーが両方のレベルを持てるようにします。

## Architecture

### Database Schema Changes

#### 1. WottLevels Table
```sql
CREATE TABLE wott_levels (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  value INTEGER NOT NULL,
  symbol VARCHAR(255),
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);
```

#### 2. Users Table Modification
```sql
ALTER TABLE users ADD COLUMN wott_level_id INTEGER;
ALTER TABLE users ADD FOREIGN KEY (wott_level_id) REFERENCES wott_levels(id);
```

### Level Hierarchy

| Level Name | Value | Symbol | Description |
|------------|-------|---------|-------------|
| アジアビジネストラスト | 0 | abt | 最上位レベル |
| 総代理店 | 1 | special_agent | 総代理店レベル |
| 代理店 | 2 | agent | 代理店レベル |
| サポーター | 3 | supporter | サポーターレベル |
| サロン | 4 | salon | サロンレベル |
| クリニック | 5 | clinic | クリニックレベル |
| お客様 | 6 | customer | 顧客レベル |

## Components and Interfaces

### 1. WottLevel Model
```ruby
class WottLevel < ApplicationRecord
  has_many :users, foreign_key: 'wott_level_id'
  
  validates :name, presence: true, uniqueness: true
  validates :value, presence: true, uniqueness: true
  
  scope :ordered, -> { order(:value) }
  
  def symbol
    case name
    when 'アジアビジネストラスト' then :abt
    when '総代理店' then :special_agent
    when '代理店' then :agent
    when 'サポーター' then :supporter
    when 'サロン' then :salon
    when 'クリニック' then :clinic
    when 'お客様' then :customer
    end
  end
end
```

### 2. User Model Extensions
```ruby
class User < ApplicationRecord
  belongs_to :level # 既存の上清液レベル
  belongs_to :wott_level, optional: true # 新しいWOTTレベル
  
  # WOTT関連のヘルパーメソッド
  def wott_level_name
    wott_level&.name || '未設定'
  end
  
  def has_wott_level?
    wott_level.present?
  end
  
  def wott_level_symbol
    wott_level&.symbol
  end
end
```

### 3. Product Price Integration
既存のProductPriceモデルを拡張してWOTTレベル対応：

```ruby
class ProductPrice < ApplicationRecord
  belongs_to :product
  belongs_to :level, optional: true
  belongs_to :wott_level, optional: true
  
  validates :price, presence: true
  validate :must_have_level_or_wott_level
  
  private
  
  def must_have_level_or_wott_level
    if level.blank? && wott_level.blank?
      errors.add(:base, 'Either level or wott_level must be present')
    end
  end
end
```

## Data Models

### Migration Files

#### 1. Create WottLevels Table
```ruby
class CreateWottLevels < ActiveRecord::Migration[8.0]
  def change
    create_table :wott_levels do |t|
      t.string :name, null: false
      t.integer :value, null: false
      t.timestamps
    end
    
    add_index :wott_levels, :name, unique: true
    add_index :wott_levels, :value, unique: true
  end
end
```

#### 2. Add WottLevel to Users
```ruby
class AddWottLevelToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :wott_level, null: true, foreign_key: true
  end
end
```

#### 3. Add WottLevel to ProductPrices
```ruby
class AddWottLevelToProductPrices < ActiveRecord::Migration[8.0]
  def change
    add_reference :product_prices, :wott_level, null: true, foreign_key: true
  end
end
```

### Seed Data
```ruby
# WottLevel seed data
wott_level_data = [
  { id: 1, name: "アジアビジネストラスト", value: 0 },
  { id: 2, name: "総代理店", value: 1 },
  { id: 3, name: "代理店", value: 2 },
  { id: 4, name: "サポーター", value: 3 },
  { id: 5, name: "サロン", value: 4 },
  { id: 6, name: "クリニック", value: 5 },
  { id: 7, name: "お客様", value: 6 }
]

WottLevel.delete_all
wott_level_data.each do |data|
  WottLevel.create!(data)
end
```

## Error Handling

### Validation Rules
1. WottLevel名の一意性チェック
2. WottLevel値の一意性チェック
3. User-WottLevel関連の整合性チェック
4. ProductPrice-WottLevel関連の整合性チェック

### Error Messages
- WottLevelが見つからない場合の適切なエラーメッセージ
- 無効なレベル設定時の警告
- データ整合性エラーの処理

## Testing Strategy

### Unit Tests
1. WottLevelモデルのバリデーションテスト
2. User-WottLevel関連のテスト
3. ProductPrice-WottLevel関連のテスト

### Integration Tests
1. レベル変更時の価格計算テスト
2. 複数レベル保持ユーザーのテスト
3. マイグレーション実行テスト

### Test Data
```ruby
# Test fixtures
wott_levels:
  abt:
    name: "アジアビジネストラスト"
    value: 0
  
  special_agent:
    name: "総代理店"
    value: 1
    
  customer:
    name: "お客様"
    value: 6

users:
  dual_level_user:
    name: "テストユーザー"
    level: agent_level
    wott_level: special_agent
```

## Implementation Notes

### Phase 1: Database Setup
1. WottLevelsテーブル作成
2. Usersテーブルにwott_level_id追加
3. 基本的なモデル関連付け

### Phase 2: Model Integration
1. WottLevelモデル作成
2. Userモデル拡張
3. ProductPriceモデル拡張

### Phase 3: Data Migration
1. 既存ユーザーのWOTTレベル設定
2. WOTT商品の価格設定
3. データ整合性チェック

### Backward Compatibility
- 既存の上清液レベルシステムは変更なし
- 既存のユーザーはwott_level_id = NULLで問題なし
- 既存のProductPriceレコードはlevel_idのみで動作継続