# クリニック予約システム 設計ドキュメント

## 概要

既存のクリニック予約システム（clinic_reservations/new画面）を拡張し、クリニック別の営業時間・休憩時間・休日設定に基づいて動的に予約可能枠を生成する機能を実装します。ユーザーは購入時に選択したクリニックで、利用可能な時間帯のみから第1～第3希望を選択できるようになります。

## アーキテクチャ

### 全体構成

```
[既存] Cart → Purchase → ClinicReservation
[新規] Clinic Management System
       ├── Clinics (基本情報)
       ├── ClinicBusinessHours (営業時間)
       ├── ClinicBreakTimes (休憩時間)
       └── ClinicHolidays (休日設定)

[新規] Availability Service
       └── 予約可能枠の動的生成

[拡張] clinic_reservations/new画面
       └── JavaScript による動的時間選択
```

### 設計原則

1. **既存システムとの互換性**: 現在のclinic_reservationsテーブルとコントローラーを維持
2. **データ駆動設計**: クリニック設定をDBで管理し、コード変更なしに運営条件を更新
3. **再利用可能性**: Service Objectパターンで予約可能枠判定ロジックを実装
4. **拡張性**: 将来的なスタッフ別予約・枠数制限・通知機能に対応できる構造

## コンポーネントと インターフェース

### 1. データモデル

#### Clinic（新規）
```ruby
class Clinic < ApplicationRecord
  belongs_to :user  # 既存のクリニックユーザーとの関連
  has_many :clinic_business_hours, dependent: :destroy
  has_many :clinic_break_times, dependent: :destroy
  has_many :clinic_holidays, dependent: :destroy
  has_many :clinic_reservations, dependent: :destroy
  
  validates :name, presence: true
  validates :user_id, presence: true, uniqueness: true
  validates :is_active, inclusion: { in: [true, false] }
  
  # 予約可能かどうかの判定
  def reservable?
    is_active && user.present? && user.level&.name&.include?('クリニック')
  end
end
```

#### User（拡張）
```ruby
class User < ApplicationRecord
  # 既存の関連に追加
  has_one :clinic, dependent: :destroy
  
  # クリニックかどうかを判定するメソッド
  def clinic?
    level&.name&.include?('クリニック')
  end
  
  # 予約可能なクリニックかどうか
  def reservable_clinic?
    clinic? && clinic&.reservable?
  end
end
```

#### ClinicBusinessHour（新規）
```ruby
class ClinicBusinessHour < ApplicationRecord
  belongs_to :clinic
  
  validates :weekday, presence: true, inclusion: { in: 0..6 }
  validates :start_time, :end_time, presence: true
  validates :clinic_id, uniqueness: { scope: :weekday }
end
```

#### ClinicBreakTime（新規）
```ruby
class ClinicBreakTime < ApplicationRecord
  belongs_to :clinic
  
  validates :weekday, presence: true, inclusion: { in: 0..6 }
  validates :start_time, :end_time, presence: true
end
```

#### ClinicHoliday（新規）
```ruby
class ClinicHoliday < ApplicationRecord
  belongs_to :clinic
  
  validates :reason, presence: true
  validate :date_or_weekday_present
  
  private
  
  def date_or_weekday_present
    errors.add(:base, "日付または曜日のいずれかを指定してください") if date.blank? && weekday.blank?
  end
end
```

#### ClinicReservation（拡張）
```ruby
class ClinicReservation < ApplicationRecord
  belongs_to :clinic  # 新しいClinicsテーブルへの関連
  # 既存の関連とメソッドは維持
  
  # 既存のclinic_idから新しいClinicへの移行が必要
end
```

### 2. サービスクラス

#### Clinic::AvailabilityService（新規）
```ruby
class Clinic::AvailabilityService
  def initialize(clinic)
    @clinic = clinic  # clinicはClinicモデルのインスタンス
  end
  
  # 指定日の予約可能な1時間枠を返す
  def available_slots(date)
    return [] if holiday?(date)
    
    business_slots = generate_business_slots(date)
    break_slots = generate_break_slots(date)
    reserved_slots = reserved_slots_for(date)
    
    business_slots - break_slots - reserved_slots
  end
  
  # 休日判定
  def holiday?(date)
    weekday = date.wday
    
    # 日付指定の休日
    @clinic.clinic_holidays.where(date: date).exists? ||
    # 曜日指定の休日
    @clinic.clinic_holidays.where(weekday: weekday, date: nil).exists?
  end
  
  private
  
  def generate_business_slots(date)
    weekday = date.wday
    business_hour = @clinic.clinic_business_hours.find_by(weekday: weekday)
    return [] unless business_hour
    
    slots = []
    current_time = business_hour.start_time
    
    while current_time < business_hour.end_time
      next_time = current_time + 1.hour
      break if next_time > business_hour.end_time
      
      slots << "#{current_time.strftime('%H:%M')}-#{next_time.strftime('%H:%M')}"
      current_time = next_time
    end
    
    slots
  end
  
  def generate_break_slots(date)
    weekday = date.wday
    break_times = @clinic.clinic_break_times.where(weekday: weekday)
    
    break_slots = []
    break_times.each do |break_time|
      current_time = break_time.start_time
      
      while current_time < break_time.end_time
        next_time = current_time + 1.hour
        break if next_time > break_time.end_time
        
        break_slots << "#{current_time.strftime('%H:%M')}-#{next_time.strftime('%H:%M')}"
        current_time = next_time
      end
    end
    
    break_slots
  end
  
  def reserved_slots_for(date)
    @clinic.clinic_reservations
           .where(status: ClinicReservation::CONFIRMED)
           .where("DATE(confirmed_date) = ?", date)
           .pluck(:confirmed_time)
           .compact
  end
end
```

### 3. APIエンドポイント

#### AvailableTimesController（新規）
```ruby
class AvailableTimesController < ApplicationController
  before_action :authenticate_user!
  
  def index
    clinic = Clinic.find(params[:clinic_id])
    date = Date.parse(params[:date])
    
    service = Clinic::AvailabilityService.new(clinic)
    available_slots = service.available_slots(date)
    
    render json: available_slots
  rescue Date::Error
    render json: { error: "Invalid date format" }, status: :bad_request
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Clinic not found" }, status: :not_found
  end
end
```

### 4. 管理画面設計

#### Admin::ClinicsController（新規）
```ruby
class Admin::ClinicsController < Admin::BaseController
  before_action :set_clinic_user, only: [:show, :edit, :update]
  
  def index
    @clinics = Clinic.includes(:user, :clinic_business_hours, :clinic_break_times, :clinic_holidays)
                     .order(:name)
    
    # 予約可能クリニックとして未登録のクリニックユーザー
    @available_clinic_users = User.joins(:level)
                                  .where(levels: { name: 'クリニック' })
                                  .where.not(id: Clinic.select(:user_id))
                                  .order(:name)
  end
  
  def show
    @business_hours = @clinic_user.clinic_business_hours.order(:weekday)
    @break_times = @clinic_user.clinic_break_times.order(:weekday, :start_time)
    @holidays = @clinic_user.clinic_holidays.order(:date, :weekday)
  end
  
  def edit
    # 営業時間の初期化（全曜日分）
    (0..6).each do |weekday|
      unless @clinic_user.clinic_business_hours.exists?(weekday: weekday)
        @clinic_user.clinic_business_hours.build(weekday: weekday)
      end
    end
  end
  
  def update
    if update_clinic_settings
      redirect_to admin_clinic_path(@clinic_user), notice: 'クリニック設定を更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_clinic_user
    @clinic_user = User.find(params[:id])
  end
  
  def update_clinic_settings
    ActiveRecord::Base.transaction do
      update_business_hours
      update_break_times
      update_holidays
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end
end
```

#### 管理画面のビュー構成

**app/views/admin/clinics/index.html.erb**
- 予約可能クリニック一覧表示
- 各クリニックの基本情報と設定状況
- 営業時間設定済み/未設定の表示
- 新しいクリニックを予約可能として追加する機能（levelがクリニックのユーザーから選択）

**app/views/admin/clinics/show.html.erb**
- クリニック詳細情報
- 営業時間・休憩時間・休日の一覧表示
- 編集ボタン

**app/views/admin/clinics/edit.html.erb**
- 営業時間設定（曜日別）
- 休憩時間設定（複数設定可能）
- 休日設定（日付指定・曜日指定）

#### 管理ダッシュボードの更新

**app/views/admin/dashboard/index.html.erb**
クイックアクションセクションに以下を追加：
```erb
<%= link_to "クリニック管理", admin_clinics_path, class: "btn btn-outline-primary" %>
```

**config/routes.rb**
管理画面のルーティング追加：
```ruby
namespace :admin do
  resources :clinics, only: [:index, :show, :edit, :update]
  get 'available_times', to: 'available_times#index'
end
```

### 5. JavaScript拡張

#### clinic_reservations.js（新規）
```javascript
class ClinicReservationManager {
  constructor() {
    this.clinicId = null;
    this.selectedDates = new Set();
    this.init();
  }
  
  init() {
    this.clinicId = document.querySelector('[name="clinic_reservation[clinic_id]"]')?.value;
    this.bindEvents();
    this.initializeDateFields();
  }
  
  bindEvents() {
    // 日付選択時のイベント
    document.querySelectorAll('[name*="preferred_date"]').forEach(field => {
      field.addEventListener('change', (e) => this.handleDateChange(e));
    });
  }
  
  async handleDateChange(event) {
    const dateField = event.target;
    const selectedDate = dateField.value;
    const timeFieldName = dateField.name.replace('date', 'time');
    const timeField = document.querySelector(`[name="${timeFieldName}"]`);
    
    if (!selectedDate || !this.clinicId) return;
    
    try {
      const response = await fetch(`/available_times?clinic_id=${this.clinicId}&date=${selectedDate}`);
      const availableSlots = await response.json();
      
      this.updateTimeOptions(timeField, availableSlots);
      this.updateSelectedDates();
      
    } catch (error) {
      console.error('Failed to fetch available times:', error);
      this.showError('予約可能時間の取得に失敗しました');
    }
  }
  
  updateTimeOptions(timeField, availableSlots) {
    // 既存のオプションをクリア
    timeField.innerHTML = '<option value="">選択してください</option>';
    
    // 利用可能な時間帯のみを追加
    availableSlots.forEach(slot => {
      const option = document.createElement('option');
      option.value = slot;
      option.textContent = slot;
      timeField.appendChild(option);
    });
    
    // 利用可能な時間帯がない場合
    if (availableSlots.length === 0) {
      const option = document.createElement('option');
      option.value = '';
      option.textContent = '予約可能な時間帯がありません';
      option.disabled = true;
      timeField.appendChild(option);
    }
  }
  
  updateSelectedDates() {
    // 重複選択の防止ロジック
    this.selectedDates.clear();
    
    document.querySelectorAll('[name*="preferred_date"]').forEach(field => {
      if (field.value) {
        this.selectedDates.add(field.value);
      }
    });
  }
  
  showError(message) {
    // エラーメッセージの表示
    const alertDiv = document.createElement('div');
    alertDiv.className = 'alert alert-warning alert-dismissible fade show';
    alertDiv.innerHTML = `
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    const form = document.querySelector('form');
    form.insertBefore(alertDiv, form.firstChild);
  }
}

// Turbo対応の初期化
document.addEventListener('DOMContentLoaded', () => new ClinicReservationManager());
document.addEventListener('turbo:load', () => new ClinicReservationManager());
```

## データモデル

### テーブル構造

#### clinics（新規）
| カラム名 | 型 | 制約 | 説明 |
|---------|---|------|------|
| id | bigint | PK | クリニックID |
| user_id | bigint | FK, NOT NULL, UNIQUE | 対応するユーザーID |
| name | string | NOT NULL | クリニック名 |
| is_active | boolean | DEFAULT true | 予約受付可能フラグ |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

#### clinic_business_hours
| カラム名 | 型 | 制約 | 説明 |
|---------|---|------|------|
| id | bigint | PK | ID |
| clinic_id | bigint | FK, NOT NULL | クリニックID（clinics.idを参照） |
| weekday | integer | NOT NULL | 曜日（0=日曜〜6=土曜） |
| start_time | time | NOT NULL | 営業開始時間 |
| end_time | time | NOT NULL | 営業終了時間 |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

**インデックス**: `clinic_id, weekday` (UNIQUE)

#### clinic_break_times
| カラム名 | 型 | 制約 | 説明 |
|---------|---|------|------|
| id | bigint | PK | ID |
| clinic_id | bigint | FK, NOT NULL | クリニックID（clinics.idを参照） |
| weekday | integer | NOT NULL | 曜日（0=日曜〜6=土曜） |
| start_time | time | NOT NULL | 休憩開始時間 |
| end_time | time | NOT NULL | 休憩終了時間 |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

#### clinic_holidays
| カラム名 | 型 | 制約 | 説明 |
|---------|---|------|------|
| id | bigint | PK | ID |
| clinic_id | bigint | FK, NOT NULL | クリニックID（clinics.idを参照） |
| date | date | NULL | 特定日の休日 |
| weekday | integer | NULL | 定期休日の曜日 |
| reason | string | NOT NULL | 休日理由 |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

#### clinic_reservations（既存テーブル - clinic_idを更新）
| カラム名 | 型 | 制約 | 説明 |
|---------|---|------|------|
| clinic_id | bigint | FK, NULL | クリニックID（clinics.idを参照、データ移行が必要） |

### データ例

#### 予約可能クリニックの登録と設定例

**ステップ1: 既存のクリニックユーザーから予約可能クリニックを選択**
```ruby
# levelが「クリニック」のユーザーを取得
clinic_users = User.joins(:level).where(levels: { name: 'クリニック' })

# その中から予約機能を提供したいクリニックを選択
ginza_clinic_user = clinic_users.find_by(name: "GINZA中央クリニック")

# 予約可能クリニックとして登録
clinic = Clinic.create!(
  user: ginza_clinic_user,
  name: ginza_clinic_user.name,
  is_active: true
)

# 営業時間（月-土 10:00-18:30）
(1..6).each do |weekday|
  clinic.clinic_business_hours.create!(
    weekday: weekday,
    start_time: "10:00",
    end_time: "18:30"
  )
end

# 休憩時間（13:00-15:00）
(1..6).each do |weekday|
  clinic.clinic_break_times.create!(
    weekday: weekday,
    start_time: "13:00",
    end_time: "15:00"
  )
end

# 定期休日（日曜）
clinic.clinic_holidays.create!(
  weekday: 0,
  reason: "定休日"
)
```

## 正確性プロパティ

*プロパティとは、システムの全ての有効な実行において真であるべき特性や動作です。これらは人間が読める仕様と機械で検証可能な正確性保証の橋渡しとなります。*

### プロパティ1: 予約可能枠生成の正確性
*任意の* クリニックと日付の組み合わせについて、生成される予約可能枠は営業時間内かつ休憩時間外かつ休日以外かつ既存予約と重複しない1時間枠のみを含む
**検証対象: 要件 2.1, 2.2, 2.3, 2.4, 2.5**

### プロパティ2: 認証・認可の一貫性
*任意の* ユーザーについて、購入履歴がある場合のみ予約画面にアクセスでき、購入履歴がない場合はアクセスが拒否される
**検証対象: 要件 1.1**

### プロパティ3: データ保存・取得の整合性
*任意の* クリニック設定（営業時間・休憩時間・休日）について、保存されたデータが取得時に同じ値で返される
**検証対象: 要件 4.1, 4.2, 4.3, 6.1, 6.2, 6.3, 6.4**

### プロパティ4: 予約処理の完全性
*任意の* 有効な予約申し込みについて、第1～第3希望が正しく保存され、確定時に適切なステータス更新と通知が行われる
**検証対象: 要件 1.4, 1.5, 3.4, 3.5**

### プロパティ5: UI動作の一貫性
*任意の* ユーザー操作（日付選択・時間選択）について、選択可能な選択肢のみが表示され、重複選択が防止される
**検証対象: 要件 1.2, 1.3, 5.1, 5.2, 5.3, 5.5**

### プロパティ6: サービスメソッドの型安全性
*任意の* 入力について、各サービスメソッド（available_slots, holiday?, business_hours_for, reserved_slots_for）が期待される型と形式の結果を返す
**検証対象: 要件 7.2, 7.3, 7.4, 7.5**

### プロパティ7: バリデーションの網羅性
*任意の* 不正な設定や入力について、適切なバリデーションエラーが発生し、システムの整合性が保たれる
**検証対象: 要件 4.5**

### プロパティ8: 管理機能の正確性
*任意の* 予約管理操作について、未確定予約の一覧表示・可否判定・確定処理が正しく動作する
**検証対象: 要件 3.1, 3.2, 3.3**

### プロパティ9: 既存システムとの互換性
*任意の* 既存データと機能について、新システム導入後も同じ動作を維持する
**検証対象: 要件 6.5**

## エラーハンドリング

### 1. データ整合性エラー
- **クリニック設定の不整合**: 営業終了時間が開始時間より早い場合
- **休憩時間の重複**: 複数の休憩時間が重複している場合
- **予約の重複**: 同じ時間枠に複数の確定予約がある場合

### 2. API エラー
- **不正な日付形式**: 日付パラメータが無効な場合
- **存在しないクリニック**: 指定されたクリニックIDが存在しない場合
- **ネットワークエラー**: API呼び出しが失敗した場合

### 3. UI エラー
- **JavaScript エラー**: 動的時間選択でエラーが発生した場合
- **フォームバリデーションエラー**: 必須項目が未入力の場合
- **重複選択エラー**: 同じ日時を複数の希望で選択した場合

### エラー処理方針
1. **グレースフルデグラデーション**: APIエラー時は固定時間帯を表示
2. **ユーザーフレンドリーなメッセージ**: 技術的エラーを分かりやすい言葉で説明
3. **ログ記録**: 全てのエラーを適切なレベルでログに記録
4. **リトライ機構**: 一時的なネットワークエラーに対する自動リトライ

## テスト戦略

### 単体テスト
- **モデルテスト**: バリデーション・関連・スコープの動作確認
- **サービステスト**: Availability Serviceの各メソッドの動作確認
- **コントローラーテスト**: 認証・認可・レスポンス形式の確認
- **JavaScriptテスト**: 動的UI更新の動作確認

### プロパティベーステスト
- **テストライブラリ**: RSpec + rspec-quickcheck gem を使用
- **実行回数**: 各プロパティテストは最低100回実行
- **ジェネレーター**: クリニック設定・日付・時間・ユーザーデータの自動生成
- **プロパティタグ**: 各テストに対応する設計ドキュメントのプロパティ番号をコメントで明記

#### プロパティテスト実装例
```ruby
# **Feature: clinic-reservation-system, Property 1: 予約可能枠生成の正確性**
RSpec.describe Clinic::AvailabilityService, type: :service do
  include RSpec::QuickCheck
  
  property "generated slots are within business hours and exclude breaks/holidays/reservations" do
    forall(
      clinic_generator,
      date_generator
    ) do |clinic, date|
      service = Clinic::AvailabilityService.new(clinic)
      slots = service.available_slots(date)
      
      # 全てのスロットが営業時間内
      slots.all? { |slot| within_business_hours?(clinic, date, slot) } &&
      # 休憩時間と重複しない
      slots.none? { |slot| overlaps_break_time?(clinic, date, slot) } &&
      # 既存予約と重複しない
      slots.none? { |slot| overlaps_existing_reservation?(clinic, date, slot) } &&
      # 休日の場合は空配列
      (service.holiday?(date) ? slots.empty? : true)
    end
  end
end
```

### 統合テスト
- **フルワークフローテスト**: 予約申し込みから確定までの完全なフロー
- **API統合テスト**: フロントエンドとバックエンドの連携確認
- **データ移行テスト**: 既存データの新システムでの動作確認
- **管理画面テスト**: クリニック設定の作成・更新・削除の動作確認

### システムテスト
- **ブラウザテスト**: Capybara を使用したE2Eテスト
- **JavaScript動作テスト**: 動的時間選択の実際のブラウザでの動作確認
- **レスポンシブテスト**: モバイルデバイスでの表示・操作確認

### パフォーマンステスト
- **API レスポンス時間**: 予約可能枠取得APIの応答時間測定
- **データベースクエリ**: N+1問題の検出と最適化
- **JavaScript パフォーマンス**: 大量の時間選択肢での動作確認