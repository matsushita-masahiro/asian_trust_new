# ボーナス検証プログラム設計書

**プロジェクト名**: アジアビジネストラスト ボーナス計算システム  
**文書バージョン**: 1.0  
**作成日**: 2025年7月23日  
**作成者**: システム開発チーム  

---

## 目次

1. [概要](#1-概要)
2. [検証対象](#2-検証対象)
3. [システム設計](#3-システム設計)
4. [検証項目詳細](#4-検証項目詳細)
5. [実装仕様](#5-実装仕様)
6. [テストケース](#6-テストケース)
7. [運用方法](#7-運用方法)
8. [付録](#8-付録)

---

## 1. 概要

### 1.1 目的

アジアビジネストラストのボーナス計算システムにおいて、複雑な階層構造と多様な販売パターンに対するボーナス計算の正確性を検証するプログラムを設計・実装する。

### 1.2 背景

現在のシステムでは以下の複雑な要素が存在する：

- **6層の階層構造**: アジアビジネストラスト → 特約代理店 → 代理店 → アドバイザー → サロン・病院
- **特殊な紹介関係**: アドバイザー→アドバイザー、特約代理店→サロン、代理店→病院
- **ステータス管理**: アクティブ、停止処分、退会
- **階層差額ボーナス**: 各レベル間の価格差によるボーナス計算
- **無資格者ボーナス**: サロン・病院の販売による上位ボーナス

### 1.3 検証の必要性

- **計算精度の保証**: 複雑なロジックでの計算ミス防止
- **データ整合性**: 階層構造とボーナス配分の整合性確認
- **パフォーマンス**: 大量データでの処理性能確認
- **回帰テスト**: システム変更時の影響確認

---

## 2. 検証対象

### 2.1 ボーナス計算ロジック

#### 2.1.1 直接販売ボーナス
```
ボーナス = (基本価格 - 自分の価格) × 数量
```

#### 2.1.2 階層差額ボーナス
```
各階層間で: 下位価格 - 上位価格 = ボーナス
```

#### 2.1.3 無資格者上位ボーナス
```
無資格者の販売 → 直近の有資格者がボーナス獲得
```

### 2.2 対象データ

- **ユーザー**: 全階層のユーザー（約60名のテストデータ）
- **購入データ**: 様々なパターンの購入履歴（20件）
- **期間**: 月次集計（今月・先月の比較）
- **商品**: 骨髄幹細胞培養上清液（基本価格: ¥50,000）

### 2.3 検証スコープ

#### 含まれるもの
- ✅ 個別購入のボーナス計算
- ✅ 月次ボーナス集計
- ✅ 階層構造の整合性
- ✅ ステータス別の除外処理
- ✅ 特殊ケースの処理

#### 含まれないもの
- ❌ UI/UXの検証
- ❌ セキュリティテスト
- ❌ 外部API連携

---

## 3. システム設計

### 3.1 アーキテクチャ概要

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   検証エンジン    │    │   レポート生成   │    │   管理画面UI    │
│                 │    │                 │    │                 │
│ - 計算検証       │───▶│ - 詳細レポート   │───▶│ - 実行ボタン     │
│ - データ検証     │    │ - エラー一覧     │    │ - 結果表示       │
│ - 整合性チェック │    │ - 統計情報       │    │ - ダウンロード   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                        データベース                              │
│  Users | Purchases | Products | Levels | ProductPrices         │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 主要コンポーネント

#### 3.2.1 BonusVerificationService
```ruby
class BonusVerificationService
  # メイン検証エンジン
  def verify_all(month = nil)
  def verify_individual_purchases
  def verify_monthly_totals
  def verify_hierarchy_consistency
end
```

#### 3.2.2 BonusCalculationValidator
```ruby
class BonusCalculationValidator
  # 独立した計算ロジック
  def calculate_expected_bonus(purchase, recipient)
  def validate_tier_difference(purchase)
  def validate_unqualified_bonus(purchase)
end
```

#### 3.2.3 VerificationReporter
```ruby
class VerificationReporter
  # レポート生成
  def generate_summary_report
  def generate_detailed_report
  def generate_error_report
end
```

### 3.3 データフロー

```
1. 検証対象データ取得
   ↓
2. 個別購入の検証
   ├─ 期待値計算
   ├─ 実際値取得
   └─ 比較・記録
   ↓
3. 月次集計の検証
   ├─ 個別ボーナス合計
   ├─ システム計算値
   └─ 差異チェック
   ↓
4. 整合性チェック
   ├─ 階層構造
   ├─ ステータス
   └─ データ品質
   ↓
5. レポート生成
   ├─ サマリー
   ├─ 詳細結果
   └─ エラー一覧
```

---

## 4. 検証項目詳細

### 4.1 個別購入ボーナス検証

#### 4.1.1 直接販売ボーナス
**検証内容**: 販売者自身のボーナス計算

**計算式**:
```
ボーナス = (商品基本価格 - 販売者価格) × 購入数量
```

**テストケース**:
- アジアビジネストラスト販売: (50,000 - 0) × 50 = 2,500,000円
- 特約代理店販売: (50,000 - 40,000) × 40 = 400,000円
- 代理店販売: (50,000 - 45,000) × 30 = 150,000円
- アドバイザー販売: (50,000 - 47,000) × 20 = 60,000円

#### 4.1.2 階層差額ボーナス
**検証内容**: 下位の販売による上位へのボーナス

**計算ロジック**:
1. 購入者から上位への階層を特定
2. 各階層の価格を取得
3. 隣接階層間の差額を計算
4. ボーナス対象者に配分

**例**: 病院(ID:35)の販売 → アドバイザー(ID:11)へのボーナス
```
病院価格: 50,000円（基本価格）
アドバイザー価格: 47,000円
ボーナス: (50,000 - 47,000) × 数量 = 3,000円 × 数量
```

#### 4.1.3 無資格者ボーナス
**検証内容**: サロン・病院の販売による上位有資格者へのボーナス

**対象**:
- サロン（レベル5）→ 直近のアドバイザー以上
- 病院（レベル6）→ 直近のアドバイザー以上

### 4.2 月次集計ボーナス検証

#### 4.2.1 個別ボーナス合計
**検証方法**:
```ruby
# 期待値: 個別購入ボーナスの合計
expected_total = user.purchases.in_month(month).sum do |purchase|
  calculate_individual_bonus(purchase, user)
end

# 実際値: システム計算値
actual_total = user.bonus_in_month(month)

# 検証
assert_equal expected_total, actual_total
```

#### 4.2.2 期間指定の正確性
**検証項目**:
- 月初・月末の境界値処理
- タイムゾーンの考慮
- 購入日時の正確な判定

### 4.3 階層構造整合性検証

#### 4.3.1 紹介関係の妥当性
**検証項目**:
- 循環参照の検出
- レベル階層の順序性
- 紹介者レベル ≤ 被紹介者レベル

**検証コード例**:
```ruby
def verify_referral_hierarchy
  User.find_each do |user|
    next unless user.referrer
    
    # レベル順序チェック
    if user.referrer.level.value > user.level.value
      add_error("Invalid level hierarchy: #{user.name}")
    end
    
    # 循環参照チェック
    if detect_circular_reference(user)
      add_error("Circular reference detected: #{user.name}")
    end
  end
end
```

#### 4.3.2 特殊ケースの検証
**対象**:
- アドバイザー → アドバイザー
- 特約代理店 → サロン
- 代理店 → 病院

### 4.4 ステータス別検証

#### 4.4.1 除外処理の確認
**検証項目**:
- 停止処分ユーザー: ボーナス = 0
- 退会ユーザー: ボーナス = 0
- アクティブユーザー: 正常計算

**テストデータ**:
- 停止処分ユーザー(ID:47): 50個販売 → ボーナス = 0円
- 退会ユーザー(ID:48): 30個販売 → ボーナス = 0円

---

## 5. 実装仕様

### 5.1 クラス設計

#### 5.1.1 BonusVerificationService
```ruby
class BonusVerificationService
  attr_reader :month, :errors, :warnings, :results

  def initialize(month = Date.current.strftime("%Y-%m"))
    @month = month
    @errors = []
    @warnings = []
    @results = {}
  end

  # メイン検証メソッド
  def verify_all
    verify_individual_purchases
    verify_monthly_totals
    verify_hierarchy_consistency
    verify_status_exclusions
    verify_edge_cases
    generate_summary
  end

  private

  def verify_individual_purchases
    Purchase.in_month(@month).includes(:user, :product).find_each do |purchase|
      verify_purchase_bonuses(purchase)
    end
  end

  def verify_purchase_bonuses(purchase)
    # 期待値計算
    expected_bonuses = BonusCalculationValidator.new.calculate_all_bonuses(purchase)
    
    # 実際値取得
    actual_bonuses = get_actual_bonuses_for_purchase(purchase)
    
    # 比較
    compare_bonus_results(expected_bonuses, actual_bonuses, purchase)
  end
end
```

#### 5.1.2 BonusCalculationValidator
```ruby
class BonusCalculationValidator
  # 独立したボーナス計算ロジック
  def calculate_all_bonuses(purchase)
    bonuses = {}
    
    # 直接販売ボーナス
    if purchase.user.bonus_eligible?
      bonuses[purchase.user.id] = calculate_direct_sales_bonus(purchase)
    end
    
    # 階層差額ボーナス
    hierarchy_bonuses = calculate_hierarchy_bonuses(purchase)
    bonuses.merge!(hierarchy_bonuses)
    
    # 無資格者ボーナス
    if !purchase.user.bonus_eligible?
      unqualified_bonus = calculate_unqualified_bonus(purchase)
      bonuses.merge!(unqualified_bonus)
    end
    
    bonuses
  end

  private

  def calculate_direct_sales_bonus(purchase)
    base_price = purchase.product.base_price
    user_price = purchase.product.product_prices
                         .find_by(level_id: purchase.user.level_id)&.price || 0
    (base_price - user_price) * purchase.quantity
  end

  def calculate_hierarchy_bonuses(purchase)
    bonuses = {}
    user = purchase.user
    
    # 階層を上に辿る
    current = user
    while current.referrer
      upper = current.referrer
      next unless upper.bonus_eligible?
      
      # 価格差を計算
      current_price = get_user_price(current, purchase.product)
      upper_price = get_user_price(upper, purchase.product)
      
      if current_price > upper_price
        bonus = (current_price - upper_price) * purchase.quantity
        bonuses[upper.id] = (bonuses[upper.id] || 0) + bonus
      end
      
      current = upper
    end
    
    bonuses
  end
end
```

### 5.2 データベース設計

#### 5.2.1 検証結果テーブル
```sql
CREATE TABLE bonus_verification_results (
  id BIGINT PRIMARY KEY,
  verification_date DATE NOT NULL,
  target_month VARCHAR(7) NOT NULL, -- YYYY-MM
  total_purchases INTEGER,
  total_errors INTEGER,
  total_warnings INTEGER,
  execution_time_ms INTEGER,
  status VARCHAR(20), -- 'completed', 'failed', 'running'
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

#### 5.2.2 検証エラーテーブル
```sql
CREATE TABLE bonus_verification_errors (
  id BIGINT PRIMARY KEY,
  verification_result_id BIGINT REFERENCES bonus_verification_results(id),
  error_type VARCHAR(50), -- 'calculation_mismatch', 'hierarchy_invalid', etc.
  severity VARCHAR(20), -- 'error', 'warning', 'info'
  purchase_id BIGINT REFERENCES purchases(id),
  user_id BIGINT REFERENCES users(id),
  expected_value DECIMAL(10,2),
  actual_value DECIMAL(10,2),
  difference DECIMAL(10,2),
  message TEXT,
  created_at TIMESTAMP
);
```

### 5.3 API設計

#### 5.3.1 検証実行API
```ruby
# POST /admin/bonus_verification
def create
  month = params[:month] || Date.current.strftime("%Y-%m")
  
  verification = BonusVerificationService.new(month)
  result = verification.verify_all
  
  render json: {
    status: 'completed',
    summary: result.summary,
    errors_count: result.errors.count,
    warnings_count: result.warnings.count,
    execution_time: result.execution_time
  }
end
```

#### 5.3.2 結果取得API
```ruby
# GET /admin/bonus_verification/:id
def show
  result = BonusVerificationResult.find(params[:id])
  
  render json: {
    result: result,
    errors: result.errors.limit(100),
    summary: result.summary_data
  }
end
```

---

## 6. テストケース

### 6.1 基本機能テスト

#### 6.1.1 直接販売ボーナステスト
```ruby
describe "直接販売ボーナス検証" do
  it "アジアビジネストラストの販売ボーナス" do
    purchase = create_purchase(
      user: asia_business_trust,
      quantity: 50,
      product: product
    )
    
    expected = (50_000 - 0) * 50 # 2,500,000円
    actual = purchase.user.bonus_for_purchase(purchase)
    
    expect(actual).to eq(expected)
  end

  it "特約代理店の販売ボーナス" do
    purchase = create_purchase(
      user: special_agent,
      quantity: 40,
      product: product
    )
    
    expected = (50_000 - 40_000) * 40 # 400,000円
    actual = purchase.user.bonus_for_purchase(purchase)
    
    expect(actual).to eq(expected)
  end
end
```

#### 6.1.2 階層差額ボーナステスト
```ruby
describe "階層差額ボーナス検証" do
  it "病院販売による上位ボーナス" do
    hospital = create_user(level: hospital_level, referrer: advisor)
    purchase = create_purchase(user: hospital, quantity: 10)
    
    # アドバイザーが受け取るボーナス
    expected = (50_000 - 47_000) * 10 # 30,000円
    actual = advisor.bonus_for_purchase(purchase)
    
    expect(actual).to eq(expected)
  end
end
```

### 6.2 特殊ケーステスト

#### 6.2.1 アドバイザー→アドバイザー
```ruby
describe "アドバイザー間紹介" do
  it "サブアドバイザーの販売による上位ボーナス" do
    sub_advisor = create_user(level: advisor_level, referrer: main_advisor)
    purchase = create_purchase(user: sub_advisor, quantity: 20)
    
    # 同レベル間でもボーナス計算される
    expected = calculate_tier_bonus(sub_advisor, main_advisor, purchase)
    actual = main_advisor.bonus_for_purchase(purchase)
    
    expect(actual).to eq(expected)
  end
end
```

#### 6.2.2 ステータス除外テスト
```ruby
describe "ステータス別除外" do
  it "停止処分ユーザーはボーナス対象外" do
    suspended_user.update!(status: 'suspended')
    purchase = create_purchase(user: suspended_user, quantity: 50)
    
    bonus = suspended_user.bonus_for_purchase(purchase)
    expect(bonus).to eq(0)
  end

  it "退会ユーザーはボーナス対象外" do
    inactive_user.update!(status: 'inactive')
    purchase = create_purchase(user: inactive_user, quantity: 30)
    
    bonus = inactive_user.bonus_for_purchase(purchase)
    expect(bonus).to eq(0)
  end
end
```

### 6.3 パフォーマンステスト

#### 6.3.1 大量データテスト
```ruby
describe "パフォーマンステスト" do
  it "1000件の購入データで5秒以内に完了" do
    create_purchases(1000)
    
    start_time = Time.current
    BonusVerificationService.new.verify_all
    end_time = Time.current
    
    execution_time = end_time - start_time
    expect(execution_time).to be < 5.seconds
  end
end
```

### 6.4 エッジケーステスト

#### 6.4.1 境界値テスト
```ruby
describe "境界値テスト" do
  it "月末最終日の購入" do
    purchase = create_purchase(
      purchased_at: Date.current.end_of_month.end_of_day
    )
    
    # 当月に含まれることを確認
    monthly_purchases = Purchase.in_month(Date.current.strftime("%Y-%m"))
    expect(monthly_purchases).to include(purchase)
  end

  it "月初最初の購入" do
    purchase = create_purchase(
      purchased_at: Date.current.beginning_of_month.beginning_of_day
    )
    
    # 当月に含まれることを確認
    monthly_purchases = Purchase.in_month(Date.current.strftime("%Y-%m"))
    expect(monthly_purchases).to include(purchase)
  end
end
```

---

## 7. 運用方法

### 7.1 実行方法

#### 7.1.1 手動実行
```bash
# 管理画面から実行
# /admin/bonus_verification

# コマンドラインから実行
rails bonus:verify

# 特定月の検証
rails bonus:verify MONTH=2025-01
```

#### 7.1.2 自動実行
```ruby
# 毎月1日に前月分を自動検証
# config/schedule.rb (whenever gem)
every 1.day.of_month, at: '2:00 am' do
  runner "BonusVerificationJob.perform_later"
end
```

### 7.2 監視・アラート

#### 7.2.1 エラー通知
```ruby
class BonusVerificationJob < ApplicationJob
  def perform(month = nil)
    result = BonusVerificationService.new(month).verify_all
    
    if result.has_errors?
      # Slack通知
      SlackNotifier.notify_bonus_verification_errors(result)
      
      # メール通知
      AdminMailer.bonus_verification_errors(result).deliver_now
    end
  end
end
```

#### 7.2.2 ダッシュボード
```ruby
# 管理画面にダッシュボード追加
class Admin::BonusVerificationController < Admin::BaseController
  def index
    @recent_results = BonusVerificationResult.recent.limit(10)
    @error_summary = BonusVerificationError.summary_by_type
    @monthly_stats = calculate_monthly_stats
  end
end
```

### 7.3 レポート出力

#### 7.3.1 PDF レポート
```ruby
class BonusVerificationPdfGenerator
  def generate(verification_result)
    pdf = Prawn::Document.new
    
    # サマリー
    pdf.text "ボーナス検証レポート", size: 20, style: :bold
    pdf.text "検証日: #{verification_result.verification_date}"
    pdf.text "対象月: #{verification_result.target_month}"
    
    # エラー一覧
    if verification_result.errors.any?
      pdf.start_new_page
      pdf.text "エラー詳細", size: 16, style: :bold
      
      verification_result.errors.each do |error|
        pdf.text "#{error.error_type}: #{error.message}"
      end
    end
    
    pdf.render
  end
end
```

#### 7.3.2 CSV エクスポート
```ruby
def export_verification_errors_csv(verification_result)
  CSV.generate(headers: true) do |csv|
    csv << [
      'エラータイプ', '重要度', 'ユーザー', '購入ID', 
      '期待値', '実際値', '差異', 'メッセージ'
    ]
    
    verification_result.errors.each do |error|
      csv << [
        error.error_type,
        error.severity,
        error.user&.name,
        error.purchase_id,
        error.expected_value,
        error.actual_value,
        error.difference,
        error.message
      ]
    end
  end
end
```

---

## 8. 付録

### 8.1 エラーコード一覧

| コード | エラータイプ | 説明 |
|--------|-------------|------|
| BV001 | calculation_mismatch | ボーナス計算値の不一致 |
| BV002 | hierarchy_invalid | 階層構造の不整合 |
| BV003 | status_exclusion_failed | ステータス除外処理の失敗 |
| BV004 | price_configuration_error | 価格設定の不整合 |
| BV005 | circular_reference | 循環参照の検出 |
| BV006 | data_integrity_error | データ整合性エラー |
| BV007 | performance_warning | パフォーマンス警告 |

### 8.2 設定パラメータ

```ruby
# config/bonus_verification.yml
development:
  max_execution_time: 300 # 5分
  error_threshold: 10
  warning_threshold: 50
  enable_performance_monitoring: true
  
production:
  max_execution_time: 600 # 10分
  error_threshold: 5
  warning_threshold: 20
  enable_performance_monitoring: true
  notification_channels:
    - slack
    - email
```

### 8.3 パフォーマンス指標

| 指標 | 目標値 | 警告値 | エラー値 |
|------|--------|--------|----------|
| 実行時間 | < 2分 | < 5分 | > 10分 |
| メモリ使用量 | < 100MB | < 200MB | > 500MB |
| データベースクエリ数 | < 100 | < 200 | > 500 |
| エラー率 | 0% | < 1% | > 5% |

### 8.4 用語集

| 用語 | 説明 |
|------|------|
| 階層差額ボーナス | 下位レベルと上位レベルの価格差によるボーナス |
| 無資格者ボーナス | サロン・病院の販売による上位有資格者へのボーナス |
| 直接販売ボーナス | 販売者自身が受け取るボーナス |
| ボーナス対象者 | アドバイザー以上のレベルのユーザー |
| 月次集計 | 指定月内の全購入に対するボーナス合計 |

---

**文書終了**

---

*この設計書は、アジアビジネストラストのボーナス計算システムの検証プログラム開発のための技術仕様書です。実装時は、この設計書を基に段階的な開発を行い、各フェーズでのテストと検証を実施してください。*