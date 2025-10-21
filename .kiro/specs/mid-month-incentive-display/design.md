# 設計書

## 概要

月の途中インセンティブ表示機能は、インセンティブ受領権利のあるユーザーが任意の日付時点でのインセンティブ計算結果と詳細明細を確認できる機能です。メインメニューに「インセンティブ」を追加し、階層ドリルダウン機能を持つ直感的なインターフェースを提供します。

## アーキテクチャ

### システム構成

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   View Layer    │    │ Controller Layer│    │   Model Layer   │
│                 │    │                 │    │                 │
│ - incentives/   │◄──►│ IncentivesCtrl  │◄──►│ User            │
│   index.html    │    │ - index         │    │ - monthly_      │
│ - incentives/   │    │ - show          │    │   incentive_    │
│   show.html     │    │ - drill_down    │    │   with_details  │
│ - incentives/   │    │ - export        │    │ Purchase        │
│   _hierarchy    │    │                 │    │ PurchaseItem    │
│ - shared/       │    │                 │    │ Level           │
│   _menu         │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 技術スタック

- **フロントエンド**: Rails ERB テンプレート、Bootstrap 5、JavaScript (Stimulus)
- **バックエンド**: Ruby on Rails 8.0.2
- **データベース**: 既存のPostgreSQL/SQLite3
- **認証**: Devise (既存)
- **エクスポート**: CSV生成、PDF生成 (wicked_pdf)

## コンポーネントと インターフェース

### 1. メニュー拡張

#### shared/_menu.html.erb の拡張
```erb
<% if current_user&.bonus_eligible? %>
  <li class="nav-item">
    <%= link_to "インセンティブ", incentives_path, class: "nav-link" %>
  </li>
<% end %>
```

### 2. IncentivesController

#### ルーティング
```ruby
# config/routes.rb
resources :incentives, only: [:index, :show] do
  member do
    get :drill_down
    get :export
  end
  collection do
    get :hierarchy
  end
end
```

#### コントローラーアクション
```ruby
class IncentivesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_incentive_permission
  before_action :set_date_range
  
  def index
    # メインのインセンティブ画面
    # 自分の直下位ユーザー一覧と売上表示
  end
  
  def show
    # 特定ユーザーの詳細インセンティブ表示
  end
  
  def drill_down
    # 階層ドリルダウン機能
  end
  
  def export
    # CSV/PDFエクスポート機能
  end
  
  private
  
  def check_incentive_permission
    # インセンティブ受領権利チェック
  end
  
  def set_date_range
    # 日付範囲設定
  end
end
```

### 3. ビューコンポーネント

#### app/views/incentives/index.html.erb
- 日付選択フォーム
- 自分のインセンティブサマリー
- 直下位ユーザー一覧テーブル
- エクスポートボタン

#### app/views/incentives/show.html.erb
- 詳細インセンティブ計算結果
- 分類別明細表示
- 購入アイテム詳細テーブル
- レベル変更履歴

#### app/views/incentives/_hierarchy_table.html.erb
- 再利用可能な階層テーブルコンポーネント
- ドリルダウンリンク付き

## データモデル

### 既存モデルの活用

#### User モデル (拡張なし)
既存のメソッドを活用:
- `bonus_eligible?` - インセンティブ受領権利チェック
- `monthly_incentive_with_details(month_str)` - 詳細インセンティブ計算
- `referrals` - 直下位ユーザー取得
- `level_at(datetime)` - 指定日時のレベル取得

#### Purchase モデル (拡張なし)
既存のスコープを活用:
- `in_month_tokyo(month_str)` - 月次データ取得
- `in_period(start_date, end_date)` - 期間指定データ取得

### 新規データ構造

#### IncentiveCalculationService
```ruby
class IncentiveCalculationService
  def initialize(user, start_date, end_date)
    @user = user
    @start_date = start_date
    @end_date = end_date
  end
  
  def calculate_detailed_incentives
    # 詳細インセンティブ計算ロジック
  end
  
  def calculate_hierarchy_sales
    # 階層別売上計算ロジック
  end
  
  private
  
  def calculate_own_sales_incentive
    # 自分の購入によるインセンティブ
  end
  
  def calculate_descendant_incentive
    # 子孫の購入による階層差額
  end
  
  def calculate_unqualified_incentive
    # 無資格者の購入によるインセンティブ
  end
end
```

## エラーハンドリング

### エラーケース

1. **権限エラー**: インセンティブ受領権利なし
   - リダイレクト先: root_path
   - メッセージ: "インセンティブ機能をご利用いただけません"

2. **データエラー**: 計算処理失敗
   - 表示: エラーメッセージとリトライボタン
   - ログ: 詳細エラー情報記録

3. **日付エラー**: 無効な日付指定
   - 表示: 日付選択フォームにエラーメッセージ
   - デフォルト: 現在月の1日〜今日

4. **エクスポートエラー**: ファイル生成失敗
   - 表示: "エクスポートに失敗しました。しばらく後にお試しください"
   - ログ: エラー詳細とスタックトレース

### エラーハンドリング戦略

```ruby
class IncentivesController < ApplicationController
  rescue_from StandardError, with: :handle_general_error
  rescue_from ArgumentError, with: :handle_date_error
  
  private
  
  def handle_general_error(exception)
    Rails.logger.error "Incentive calculation error: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    
    flash[:alert] = "処理中にエラーが発生しました。しばらく後にお試しください。"
    redirect_to incentives_path
  end
  
  def handle_date_error(exception)
    flash[:alert] = "日付の指定に問題があります。正しい日付を選択してください。"
    redirect_to incentives_path
  end
end
```

## テスト戦略

### 単体テスト

#### IncentivesController テスト
```ruby
RSpec.describe IncentivesController, type: :controller do
  describe "GET #index" do
    context "when user has incentive permission" do
      # 正常ケースのテスト
    end
    
    context "when user does not have incentive permission" do
      # 権限エラーケースのテスト
    end
  end
  
  describe "GET #drill_down" do
    # ドリルダウン機能のテスト
  end
  
  describe "GET #export" do
    # エクスポート機能のテスト
  end
end
```

#### IncentiveCalculationService テスト
```ruby
RSpec.describe IncentiveCalculationService do
  describe "#calculate_detailed_incentives" do
    # 詳細計算ロジックのテスト
  end
  
  describe "#calculate_hierarchy_sales" do
    # 階層売上計算のテスト
  end
end
```

### 統合テスト

#### システムテスト
```ruby
RSpec.describe "Incentive Management", type: :system do
  scenario "User views incentive details" do
    # インセンティブ詳細表示のE2Eテスト
  end
  
  scenario "User drills down hierarchy" do
    # 階層ドリルダウンのE2Eテスト
  end
  
  scenario "User exports incentive data" do
    # エクスポート機能のE2Eテスト
  end
end
```

### パフォーマンステスト

#### 負荷テスト観点
- 大量の下位ユーザーがいる場合の表示速度
- 複雑な階層構造での計算処理時間
- エクスポート処理の実行時間

#### 最適化戦略
- データベースクエリの最適化（N+1問題の回避）
- キャッシュ機能の実装（Redis使用検討）
- ページネーション実装
- バックグラウンドジョブでのエクスポート処理

## セキュリティ考慮事項

### アクセス制御
- インセンティブ受領権利のチェック
- 他ユーザーのデータへの不正アクセス防止
- 階層外ユーザーへのアクセス制限

### データ保護
- 個人情報の適切な表示制限
- エクスポートデータの暗号化
- ログ出力時の機密情報マスキング

### CSRF対策
- Rails標準のCSRF保護機能活用
- フォーム送信時のトークン検証

## 実装フェーズ

### フェーズ1: 基本機能
1. メニュー追加
2. IncentivesController基本実装
3. 基本的なビュー作成
4. 権限チェック機能

### フェーズ2: 詳細機能
1. IncentiveCalculationService実装
2. 詳細インセンティブ表示
3. 階層ドリルダウン機能
4. 日付選択機能

### フェーズ3: 拡張機能
1. エクスポート機能
2. レベル変更履歴表示
3. エラーハンドリング強化
4. パフォーマンス最適化

### フェーズ4: テストと最適化
1. 単体テスト実装
2. 統合テスト実装
3. パフォーマンステスト
4. セキュリティテスト