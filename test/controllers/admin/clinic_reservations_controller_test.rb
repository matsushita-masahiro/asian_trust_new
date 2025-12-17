require "test_helper"

class Admin::ClinicReservationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Create test data manually
    @admin_level = Level.find_or_create_by(name: "アジアビジネストラスト") { |l| l.value = 100 }
    @user_level = Level.find_or_create_by(name: "レベル1") { |l| l.value = 1 }
    
    @admin = User.create!(
      name: "管理者",
      email: "admin_#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      phone: "090-#{rand(1000..9999)}-#{rand(1000..9999)}",
      level: @admin_level,
      status: "active"
    )
    
    @user = User.create!(
      name: "テストユーザー",
      email: "user_#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      phone: "090-#{rand(1000..9999)}-#{rand(1000..9999)}",
      level: @user_level,
      status: "active"
    )
    
    @purchase = Purchase.create!(
      user: @user,
      purchased_at: 1.day.ago,
      payment_type: "cash",
      status: "built"
    )
    
    @clinic_reservation = ClinicReservation.create!(
      user: @user,
      purchase: @purchase,
      treatment_methods: "幹細胞治療",
      preferred_date_1: Date.current + 1.week,
      preferred_time_1: "10:00-11:00",
      disease_name: "テスト疾患",
      current_treatment: "現在の治療法",
      current_condition: "現在の状態",
      questions: "質問事項",
      status: 0
    )
    
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
  end

  test "should get index" do
    sign_in @admin
    get admin_clinic_reservations_path
    assert_response :success
  end

  test "should get show" do
    sign_in @admin
    get admin_clinic_reservation_path(@clinic_reservation)
    assert_response :success
  end

  test "should get edit" do
    sign_in @admin
    get edit_admin_clinic_reservation_path(@clinic_reservation)
    assert_response :success
  end

  test "should update clinic reservation" do
    sign_in @admin
    patch admin_clinic_reservation_path(@clinic_reservation), params: {
      clinic_reservation: {
        confirmed_date: Date.current + 1.week,
        confirmed_time: "10:00-11:00",
        status: "confirmed"
      }
    }
    assert_redirected_to admin_clinic_reservation_path(@clinic_reservation)
  end
end
