# ユーザーレベル履歴管理機能 設計書

## 概要

ユーザーのレベル変更履歴を管理し、購入時点でのレベルに基づいて正確なインセンティブ計算を行うシステムの設計。

## アーキテクチャ

### データベース設計

#### 新規テーブル: user_level_histories

```sql
CREATE TABLE user_level_histories (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  level_id INTEGER NOT NULL,
  previous_level_id INTEGER NULL,
  effective_from DATETIME NOT NULL,
  effective_to DATETIME NULL,
  change_reason TEXT NOT NULL,
  changed_by_id INTEGER NOT NULL,
  ip_address VARCHAR(45),
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (level_id) REFERENCES levels(id),
  FOREIGN KEY (previous_level_id) REFERENCES levels(id),
  FOREIGN KEY (changed_by_id) REFERENCES users(id)
);

-- インデックス
CREATE INDEX idx_user_level_histories_user_id ON user_level_histories(user_id);
CREATE INDEX idx_user_level_histories_effective_dates ON user_level_histories(user_id, effective_from, effective_to);
CREATE INDEX idx_user_level_histories_changed_by ON user_level_histories(changed_by_id);
CREATE INDEX idx_user_level_histories_created_at ON user_level_histories(created_at);
```

#### 既存テーブルの変更

- `users`テーブルの`level_id`は現在のレベルとして維持
- 履歴テーブルと併用してデータの整合性を保つ

### モデル設計

#### UserLevelHistory モデル

```ruby
class UserLevelHistory < ApplicationRecord
  belongs_to :user
  belongs_to :level
  belongs_to :changed_by, class_name: 'User', optional: true
  
  validates :effective_from, presence: true
  validates :user_id, presence: true
  validates :level_id, presence: true
  validates :change_reason, presence: true
  
  scope :effective_at, ->(datetime) {
    where('effective_from <= ? AND (effective_to IS NULL OR effective_to > ?)', datetime, datetime)
  }
  
  scope :current, -> { where(effective_to: nil) }
  scope :historical, -> { where.not(effective_to: nil) }
  scope :recent, -> { order(created_at: :desc) }
end
```

#### User モデルの拡張

```ruby
class User < ApplicationRecord
  has_many :user_level_histories, dependent: :destroy
  
  # 指定日時でのレベルを取得
  def level_at(datetime)
    history = user_level_histories.effective_at(datetime).first
    history&.level || level
  end
  
  # 指定日時での商品価格を取得
  def product_price_at(product, datetime)
    level_at_time = level_at(datetime)
    product.product_prices.find_by(level_id: level_at_time.id)&.price || 0
  end
  
  # レベル変更時の履歴更新
  def update_level_history(new_level_id)
    return if level_id == new_level_id
    
    transaction do
      # 現在の履歴を終了
      current_history = user_level_histories.current.first
      if current_history
        current_history.update!(effective_to: Time.current)
      end
      
      # 新しい履歴を作成
      user_level_histories.create!(
        level_id: new_level_id,
        effective_from: Time.current
      )
      
      # ユーザーの現在レベルを更新
      update!(level_id: new_level_id)
    end
  end
end
```

### コンポーネント設計

#### 1. LevelHistoryManager

レベル履歴の管理を担当するサービスクラス

```ruby
class LevelHistoryManager
  def self.initialize_user_history(user)
    # ユーザー作成時の初期履歴作成
  end
  
  def self.change_user_level(user, new_level_id)
    # レベル変更処理
  end
  
  def self.migrate_existing_users
    # 既存ユーザーの履歴作成
  end
end
```

#### 2. 既存インセンティブ計算の全面改修

**User モデルの既存メソッド更新:**

```ruby
class User < ApplicationRecord
  # 履歴ベースのインセンティブ単価計算
  def incentive_unit_price_for_item(purchase_item)
    return 0 unless bonus_eligible?

    purchase = purchase_item.purchase
    purchase_user = purchase.user
    product = purchase_item.product
    purchase_date = purchase.purchased_at
    seller_price = purchase_item.seller_price

    # 購入時点での自分のレベルを取得
    my_level_at_purchase = level_at(purchase_date)
    my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
    
    # 自分の販売の場合：基本単価 - 購入時点での自分の購入単価
    if purchase_user == self
      base_price = product.base_price
      incentive_unit = base_price - my_price
    else
      # 他人の販売の場合：販売店の購入単価 - 購入時点での自分の購入単価
      incentive_unit = seller_price - my_price
    end
    
    incentive_unit > 0 ? incentive_unit : 0
  end

  # 履歴ベースのボーナス計算（期間指定）
  def bonus_in_period(start_date, end_date)
    return 0 unless bonus_eligible?

    range = start_date..end_date
    total_bonus = 0

    # 自分の販売に対するボーナス
    my_purchases = purchases.includes(purchase_items: :product).where(purchased_at: range)
    my_purchases.each do |purchase|
      purchase.purchase_items.each do |item|
        # 購入時点での自分のレベルを使用
        my_level_at_purchase = level_at(purchase.purchased_at)
        product = item.product
        base_price = product.base_price
        my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
        total_bonus += (base_price - my_price) * item.quantity
      end
    end

    # 子孫の販売に対するボーナス
    descendant_purchases = Purchase.includes(purchase_items: :product, user: :level)
                                   .where(user_id: descendant_ids)
                                   .where(purchased_at: range)

    descendant_purchases.each do |purchase|
      purchase.purchase_items.each do |item|
        # 購入時点での両者のレベルを使用
        purchase_user_level = purchase.user.level_at(purchase.purchased_at)
        my_level_at_purchase = level_at(purchase.purchased_at)
        
        # 階層差額計算（購入時点でのレベルベース）
        product = item.product
        purchase_user_price = product.product_prices.find_by(level_id: purchase_user_level.id)&.price || 0
        my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
        
        if purchase_user_price > my_price
          diff = purchase_user_price - my_price
          total_bonus += diff * item.quantity
        end
      end
    end

    total_bonus
  end
end
```

**影響を受ける既存メソッド:**
- `incentive_unit_price_for_item` → 履歴ベース計算に変更
- `bonus_for_purchase_item` → 履歴ベース計算に変更  
- `bonus_in_period` → 履歴ベース計算に変更
- `bonus_in_month` → `bonus_in_period`を使用するため自動的に履歴ベースになる
- `own_monthly_sales_total` → 変更不要（販売金額のみ）

**請求書・領収書関連の影響:**
- **Invoice モデル**: 月次インセンティブ計算が履歴ベースになる
- **請求書生成処理**: 対象月の全購入について購入時点でのレベルで計算
- **領収書生成処理**: 個別購入のインセンティブが履歴ベースで計算
- **月次集計処理**: 期間内の全購入で購入時点レベルを使用

**その他の影響を受ける機能:**

1. **管理画面のレポート・統計機能**
   - ユーザー一覧でのレベル表示（履歴考慮）
   - 売上・インセンティブ集計（履歴ベース計算）
   - ダッシュボードの統計情報（履歴ベース）

2. **ユーザー詳細画面**
   - レベル履歴の表示
   - 過去のインセンティブ再計算機能
   - レベル変更の影響分析

3. **データエクスポート機能**
   - CSV出力時のインセンティブ計算（履歴ベース）
   - レポート生成時の計算（履歴ベース）

4. **API レスポンス**
   - ユーザー情報API（レベル履歴含む）
   - インセンティブ計算API（履歴ベース）

5. **バッチ処理**
   - 月次集計バッチ（履歴ベース計算）
   - データ整合性チェックバッチ
   - 履歴データのクリーンアップバッチ

**具体的な変更例:**

```ruby
# 管理画面でのユーザー一覧
class Admin::UsersController < ApplicationController
  def index
    @users = User.includes(:user_level_histories, :level)
    # 各ユーザーの現在レベルと最新変更日を表示
  end
end

# ダッシュボードの統計
class Admin::DashboardController < ApplicationController
  def index
    # 履歴ベースでの月次インセンティブ集計
    @monthly_incentives = User.bonus_eligible.sum do |user|
      user.bonus_in_period(@current_month_start, @current_month_end)
    end
  end
end

# データエクスポート
class ExportService
  def generate_incentive_report(start_date, end_date)
    User.bonus_eligible.map do |user|
      {
        user_name: user.name,
        current_level: user.level.name,
        level_changes: user.user_level_histories.where(effective_from: start_date..end_date).count,
        total_incentive: user.bonus_in_period(start_date, end_date)
      }
    end
  end
end

# API レスポンス
class Api::UsersController < ApplicationController
  def show
    user = User.find(params[:id])
    render json: {
      id: user.id,
      name: user.name,
      current_level: user.level.name,
      level_history: user.user_level_histories.recent.limit(10),
      current_month_incentive: user.bonus_in_month
    }
  end
end
```

**データベースクエリの最適化が必要な箇所:**
- ユーザー一覧での大量データ表示
- 月次集計での全ユーザー計算
- レポート生成での期間指定計算
- ダッシュボードでのリアルタイム統計

## データフロー

### 1. レベル変更フロー

```
管理者がレベル変更
↓
User#update_level_history呼び出し
↓
現在の履歴レコードのeffective_toを更新
↓
新しい履歴レコードを作成
↓
ユーザーのlevel_idを更新
```

### 2. インセンティブ計算フロー

```
購入データを取得
↓
購入日時を特定
↓
User#level_at(購入日時)でレベル取得
↓
そのレベルの商品価格を取得
↓
インセンティブ単価を計算
↓
数量を掛けてインセンティブ算出
```

## インターフェース設計

### 管理画面の拡張

#### ユーザー詳細画面

- レベル履歴セクションを追加
- 時系列でレベル変更を表示
- 各レベルの有効期間を明示
- 「レベル変更」ボタンを追加

#### 既存ユーザー編集画面の拡張 (`/admin/users/:id/edit`)

**レベル変更セクションの追加:**
- 現在のレベル表示
- 新しいレベル選択（ドロップダウン）
- レベル変更理由入力欄（テキストエリア）
- 「レベル変更時は理由を入力してください」の注意書き

**セキュリティ認証:**
- レベル変更時の管理者パスワード再入力欄
- 「この操作には管理者パスワードが必要です」の警告表示
- パスワード入力フィールド（type="password"）

**JavaScript確認機能:**
- レベルが変更された場合の確認ダイアログ
- 変更理由が未入力の場合の警告
- パスワードが未入力の場合の警告
- 変更前後のレベル比較表示
- 「この操作は取り消せません」の警告メッセージ

**フォーム送信時の処理:**
- 管理者パスワードの認証チェック
- レベル変更があった場合のみ履歴レコード作成
- 変更理由の必須チェック
- 認証失敗時のエラーメッセージ表示
- 成功時のフラッシュメッセージ表示

#### ユーザー一覧画面の拡張

- 最近レベル変更されたユーザーのハイライト表示
- レベル変更日時の表示（最新の変更のみ）

#### レベル変更履歴一覧画面 (`/admin/level_changes`)

**機能:**
- 全ユーザーのレベル変更履歴を一覧表示
- 日付範囲での絞り込み
- ユーザー名での検索
- 変更前後のレベルでの絞り込み
- CSV出力機能

**表示項目:**
- 変更日時
- ユーザー名
- 変更前レベル
- 変更後レベル
- 変更理由
- 変更者（管理者名）

## エラーハンドリング

### データ整合性エラー

- 履歴の重複チェック
- 有効期間の論理チェック
- 外部キー制約違反の処理

### パフォーマンス考慮

- 履歴テーブルのインデックス最適化
- 頻繁にアクセスされる現在レベルのキャッシュ
- 大量データ処理時のバッチ処理

## 移行戦略

### フェーズ1: テーブル作成と基本機能

1. `user_level_histories`テーブル作成
2. モデルとリレーション定義
3. 基本的な履歴管理機能

### フェーズ2: 既存データ移行

1. 既存ユーザーの履歴レコード作成
2. データ整合性チェック
3. 移行結果の検証

### フェーズ3: インセンティブ計算の全面更新

1. **既存メソッドの履歴ベース化**
   - `incentive_unit_price_for_item`の更新
   - `bonus_for_purchase_item`の更新
   - `bonus_in_period`の更新
   - 全ての計算で`level_at(purchase_date)`を使用

2. **計算結果の検証**
   - 移行前後の計算結果比較
   - テストデータでの検証
   - 既存データとの整合性チェック

3. **段階的な切り替え**
   - フィーチャーフラグによる新旧計算の切り替え
   - 管理画面での計算方式選択機能
   - 問題発生時のロールバック機能

4. **請求書・領収書システムの更新**
   - 月次インセンティブ計算の履歴ベース化
   - 個別購入インセンティブ計算の履歴ベース化
   - 既存の請求書データの再計算機能
   - 計算結果の差異レポート機能

5. **管理画面・API・バッチ処理の更新**
   - 管理画面のレポート・統計機能の履歴ベース化
   - ユーザー詳細画面でのレベル履歴表示
   - データエクスポート機能の履歴ベース化
   - API レスポンスでのレベル履歴情報追加
   - 月次集計バッチの履歴ベース化

6. **パフォーマンス最適化**
   - 履歴検索のクエリ最適化
   - 頻繁にアクセスされるデータのキャッシュ
   - インデックスの追加・調整
   - 請求書生成時の一括計算処理
   - 大量データ処理時のバッチ最適化

### フェーズ4: 管理画面の拡張

1. 履歴表示機能
2. レベル変更画面の実装
3. レベル変更履歴一覧画面
4. ユーザー一覧画面の拡張
5. 管理者向けレポート機能

## テスト戦略

### 単体テスト

- モデルのバリデーション
- 履歴検索ロジック
- インセンティブ計算ロジック

### 統合テスト

- レベル変更フロー
- **履歴ベースインセンティブ計算の正確性**
  - レベル変更前後の購入データでの計算検証
  - 複数回レベル変更があったユーザーでの計算検証
  - 期間をまたぐ購入データでの計算検証
- データ移行処理
- **既存計算結果との比較テスト**
  - 移行前後での計算結果の一致確認
  - エッジケースでの動作確認
- **請求書・領収書の計算検証**
  - 既存の請求書データとの整合性確認
  - レベル変更をまたぐ月の請求書計算検証
  - 個別購入の領収書計算検証
- **管理画面・API・バッチ処理の検証**
  - 管理画面での統計情報の正確性確認
  - API レスポンスでのレベル履歴情報の正確性
  - 月次集計バッチの計算結果検証
  - データエクスポート機能の整合性確認

### パフォーマンステスト

- 大量履歴データでの検索性能
- インセンティブ計算の処理時間
- 同時アクセス時の整合性

## セキュリティ考慮事項

### レベル変更時の認証強化

- **管理者パスワード再認証**: レベル変更時に現在ログイン中の管理者のパスワード再入力を必須とする
- **セッション確認**: 管理者セッションの有効性を再確認
- **IPアドレス記録**: レベル変更操作時のIPアドレスを履歴に記録

### 権限制御

- **管理者権限チェック**: `admin`フラグがtrueのユーザーのみレベル変更可能
- **自己変更禁止**: 管理者が自分自身のレベルを変更することを禁止
- **上位レベル制限**: 管理者が自分より上位のレベルに変更することを制限

### 監査ログ

- **詳細ログ記録**: 変更者、変更日時、変更前後のレベル、理由、IPアドレス
- **失敗ログ**: パスワード認証失敗や不正アクセス試行の記録
- **ログ改ざん防止**: 履歴データの不正な変更や削除を防ぐ仕組み

### 追加セキュリティ機能

- **操作頻度制限**: 短時間での連続レベル変更を制限
- **通知機能**: レベル変更時の管理者への通知メール
- **バックアップ**: 変更前の状態を自動バックアップ

## 運用考慮事項

### データ管理
- **履歴データのアーカイブ戦略**: 古い履歴データの定期的なアーカイブ
- **データ整合性チェック**: 定期的な履歴データと現在データの整合性確認
- **履歴データのクリーンアップ**: 不要な履歴データの削除ルール

### バックアップ・復旧
- **バックアップとリストア手順**: 履歴データを含む完全バックアップ
- **障害時の復旧手順**: レベル履歴データの復旧プロセス
- **データ移行時の検証**: 移行前後でのデータ整合性確認

### 監視・アラート
- **パフォーマンス監視**: 履歴検索クエリの実行時間監視
- **データ増加監視**: 履歴テーブルのサイズ増加監視
- **計算結果監視**: インセンティブ計算結果の異常値検知

### メンテナンス
- **定期メンテナンス**: インデックスの再構築、統計情報の更新
- **データ品質チェック**: 履歴データの品質確認バッチ
- **システム負荷分散**: 大量計算処理の時間分散