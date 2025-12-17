require "test_helper"

class ClinicReservationTest < ActiveSupport::TestCase
  def setup
    # Create test data manually to avoid fixture issues
    @level = Level.find_or_create_by(name: "レベル1") { |l| l.value = 1 }
    @clinic_level = Level.find_or_create_by(name: "クリニック") { |l| l.value = 10 }
    
    # Use a unique email for each test run
    unique_email = "test_#{SecureRandom.hex(4)}@example.com"
    unique_phone = "090-#{rand(1000..9999)}-#{rand(1000..9999)}"
    
    @user = User.create!(
      name: "テストユーザー",
      email: unique_email,
      password: "password123",
      phone: unique_phone,
      level: @level,
      status: "active"
    )
    
    @purchase = Purchase.create!(
      user: @user,
      purchased_at: 1.day.ago,
      payment_type: "cash",
      status: "built"
    )
  end

  # 既存データとの互換性テスト
  test "existing data compatibility - can read existing reservations with nil clinic_id" do
    # 既存データのような予約を作成（clinic_idがnil）
    reservation = ClinicReservation.create!(
      user: @user,
      purchase: @purchase,
      clinic_id: nil,
      treatment_methods: '["骨髄幹細胞培養上清液お申込みの方：点滴"]',
      preferred_date_1: Date.current + 1.week,
      preferred_time_1: "10:00-11:00",
      preferred_date_2: Date.current + 2.weeks,
      preferred_time_2: "14:00-15:00",
      preferred_date_3: Date.current + 3.weeks,
      preferred_time_3: "16:00-17:00",
      disease_name: "テスト疾患",
      current_condition: "テスト状態",
      status: ClinicReservation::PENDING
    )

    # 既存データが正常に読み取れることを確認
    assert_not_nil reservation
    assert_equal @user, reservation.user
    assert_equal @purchase, reservation.purchase
    assert_nil reservation.clinic_id
    assert_equal "10:00-11:00", reservation.preferred_time_1
    assert_equal "14:00-15:00", reservation.preferred_time_2
    assert_equal "16:00-17:00", reservation.preferred_time_3
    assert reservation.pending?
  end

  test "existing data compatibility - preferred_time fields work with various formats" do
    reservation = ClinicReservation.create!(
      user: @user,
      purchase: @purchase,
      treatment_methods: '["骨髄幹細胞培養上清液お申込みの方：点滴"]',
      preferred_date_1: Date.current + 1.week,
      preferred_time_1: "10:00-11:00",  # 新形式
      preferred_date_2: Date.current + 2.weeks,
      preferred_time_2: "午後2時",      # 旧形式（もしあれば）
      disease_name: "テスト疾患",
      current_condition: "テスト状態",
      status: ClinicReservation::PENDING
    )

    # 両方の形式が保存・取得できることを確認
    assert_equal "10:00-11:00", reservation.preferred_time_1
    assert_equal "午後2時", reservation.preferred_time_2
  end

  test "existing data compatibility - treatment_methods JSON parsing" do
    # 既存のJSONフォーマットでの治療方法
    reservation = ClinicReservation.create!(
      user: @user,
      purchase: @purchase,
      treatment_methods: '["骨髄幹細胞培養上清液お申込みの方：点滴", "骨髄幹細胞培養上清液お申込みの方：静脈注射"]',
      preferred_date_1: Date.current + 1.week,
      preferred_time_1: "10:00-11:00",
      disease_name: "テスト疾患",
      current_condition: "テスト状態",
      status: ClinicReservation::PENDING
    )

    # JSONパースが正常に動作することを確認
    methods = reservation.treatment_methods_array
    assert_equal 2, methods.length
    assert_includes methods, "骨髄幹細胞培養上清液お申込みの方：点滴"
    assert_includes methods, "骨髄幹細胞培養上清液お申込みの方：静脈注射"
    
    # 骨髄幹細胞治療の判定が正常に動作することを確認
    assert reservation.has_stem_cell_treatment?
  end

  test "existing data compatibility - handles invalid JSON gracefully" do
    reservation = ClinicReservation.create!(
      user: @user,
      purchase: @purchase,
      treatment_methods: 'invalid json',  # 不正なJSON
      preferred_date_1: Date.current + 1.week,
      preferred_time_1: "10:00-11:00",
      disease_name: "テスト疾患",
      current_condition: "テスト状態",
      status: ClinicReservation::PENDING
    )

    # 不正なJSONでも空配列を返すことを確認
    assert_equal [], reservation.treatment_methods_array
    assert_not reservation.has_stem_cell_treatment?
  end

  test "existing data compatibility - status constants remain unchanged" do
    # ステータス定数が変更されていないことを確認
    assert_equal 0, ClinicReservation::PENDING
    assert_equal 1, ClinicReservation::CONFIRMED
    assert_equal 2, ClinicReservation::COMPLETED
    assert_equal 3, ClinicReservation::CANCELLED
  end

  test "existing data compatibility - status methods work correctly" do
    reservation = ClinicReservation.create!(
      user: @user,
      purchase: @purchase,
      treatment_methods: '["骨髄幹細胞培養上清液お申込みの方：点滴"]',
      preferred_date_1: Date.current + 1.week,
      preferred_time_1: "10:00-11:00",
      disease_name: "テスト疾患",
      current_condition: "テスト状態",
      status: ClinicReservation::PENDING
    )

    # ステータス判定メソッドが正常に動作することを確認
    assert reservation.pending?
    assert_not reservation.confirmed?
    assert_not reservation.completed?
    assert_not reservation.cancelled?
    assert_equal '予約申込中', reservation.status_name

    # ステータス変更後の動作確認
    reservation.update!(status: ClinicReservation::CONFIRMED)
    assert_not reservation.pending?
    assert reservation.confirmed?
    assert_equal '予約確定', reservation.status_name
  end

  test "existing data compatibility - works with new clinic association" do
    # 新しいクリニックシステムとの互換性テスト
    clinic_user = User.create!(
      email: "clinic_#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "テストクリニック",
      phone: "090-#{rand(1000..9999)}-#{rand(1000..9999)}",
      level: @clinic_level
    )
    
    clinic = Clinic.create!(
      user: clinic_user,
      name: "テストクリニック",
      is_active: true
    )

    # 新しいクリニックシステムでの予約作成
    reservation = ClinicReservation.create!(
      user: @user,
      purchase: @purchase,
      clinic: clinic,
      treatment_methods: '["骨髄幹細胞培養上清液お申込みの方：点滴"]',
      preferred_date_1: Date.current + 1.week,
      preferred_time_1: "10:00-11:00",
      disease_name: "テスト疾患",
      current_condition: "テスト状態",
      status: ClinicReservation::PENDING
    )

    # 新しいクリニック関連付けが正常に動作することを確認
    assert_equal clinic, reservation.clinic
    assert_equal clinic_user, reservation.clinic.user
    assert_equal "テストクリニック", reservation.clinic.name
  end

  test "existing data compatibility - optional clinic association" do
    # clinic関連付けがoptionalであることを確認
    reservation = ClinicReservation.create!(
      user: @user,
      purchase: @purchase,
      clinic: nil,  # clinicがnilでも作成できる
      treatment_methods: '["骨髄幹細胞培養上清液お申込みの方：点滴"]',
      preferred_date_1: Date.current + 1.week,
      preferred_time_1: "10:00-11:00",
      disease_name: "テスト疾患",
      current_condition: "テスト状態",
      status: ClinicReservation::PENDING
    )

    assert_nil reservation.clinic
    assert_nil reservation.clinic_id
    # 他の機能は正常に動作する
    assert reservation.pending?
    assert reservation.has_stem_cell_treatment?
  end

  test "existing data compatibility - validates required fields" do
    # 必須フィールドのバリデーションが既存データでも動作することを確認
    reservation = ClinicReservation.new(
      user: @user,
      purchase: @purchase
    )

    assert_not reservation.valid?
    assert_includes reservation.errors[:treatment_methods], "を入力してください"
    assert_includes reservation.errors[:preferred_date_1], "を入力してください"
    assert_includes reservation.errors[:preferred_time_1], "を入力してください"
  end

  test "existing data compatibility - conditional validations for stem cell treatment" do
    # 骨髄幹細胞治療の場合の条件付きバリデーション
    reservation = ClinicReservation.new(
      user: @user,
      purchase: @purchase,
      treatment_methods: '["骨髄幹細胞培養上清液お申込みの方：点滴"]',
      preferred_date_1: Date.current + 1.week,
      preferred_time_1: "10:00-11:00"
      # disease_name, current_conditionを意図的に省略
    )

    assert_not reservation.valid?
    assert_includes reservation.errors[:disease_name], "を入力してください"
    assert_includes reservation.errors[:current_condition], "を入力してください"

    # 非骨髄幹細胞治療の場合はバリデーションされない
    reservation.treatment_methods = '["その他の治療"]'
    reservation.valid? # バリデーションを実行
    assert_not_includes reservation.errors[:disease_name], "を入力してください"
    assert_not_includes reservation.errors[:current_condition], "を入力してください"
  end
end
