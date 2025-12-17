require "test_helper"

class ClinicReservationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Create test data manually
    @level = Level.find_or_create_by(name: "レベル1") { |l| l.value = 1 }
    @clinic_level = Level.find_or_create_by(name: "クリニック") { |l| l.value = 10 }
    
    @admin_level = Level.find_or_create_by(name: "アジアビジネストラスト") { |l| l.value = 100 }
    
    @user = User.create!(
      name: "テストユーザー",
      email: "test_#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      phone: "090-#{rand(1000..9999)}-#{rand(1000..9999)}",
      level: @admin_level,  # 管理者権限でテスト
      status: "active"
    )
    
    @clinic_user = User.create!(
      name: "テストクリニック",
      email: "clinic_#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      phone: "090-#{rand(1000..9999)}-#{rand(1000..9999)}",
      level: @clinic_level,
      status: "active"
    )
    
    @purchase = Purchase.create!(
      user: @user,
      purchased_at: 1.day.ago,
      payment_type: "cash",
      status: "paid"
    )
    
    # Create delivery information for clinic delivery
    DeliveryInformation.create!(
      purchase: @purchase,
      delivery_type: "clinic",
      clinic: @clinic_user,
      delivery_address: "テスト住所"
    )
    
    @clinic_reservation = ClinicReservation.create!(
      user: @user,
      purchase: @purchase,
      treatment_methods: '["幹細胞治療"]',
      preferred_date_1: Date.current + 1.week,
      preferred_time_1: "10:00-11:00",
      disease_name: "テスト疾患",
      current_treatment: "現在の治療法",
      current_condition: "現在の状態",
      questions: "質問事項",
      status: 0
    )
    
  end

  test "should get new" do
    sign_in @user
    get new_purchase_clinic_reservation_path(@purchase)
    assert_response :success
  end

  test "should create clinic reservation" do
    sign_in @user
    post purchase_clinic_reservations_path(@purchase), params: {
      clinic_reservation: {
        treatment_method: "幹細胞治療",
        preferred_date_1: Date.current + 1.week,
        preferred_time_1: "10:00-11:00",
        preferred_date_2: Date.current + 2.weeks,
        preferred_time_2: "14:00-15:00",
        disease_name: "テスト疾患",
        current_treatment: "現在の治療法",
        current_condition: "現在の状態"
      }
    }
    
    # レスポンスの確認
    if response.status == 422
      puts "Validation errors: #{response.body}"
    end
    
    # 作成されたかどうかを確認
    reservation = ClinicReservation.last
    if reservation
      assert_redirected_to clinic_reservation_path(reservation)
    else
      puts "No reservation was created"
      assert false, "Clinic reservation was not created"
    end
  end

  test "should get show" do
    sign_in @user
    get clinic_reservation_path(@clinic_reservation)
    assert_response :success
  end

  test "should get index" do
    sign_in @user
    get clinic_reservations_path
    assert_response :success
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
end
