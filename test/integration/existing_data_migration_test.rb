require "test_helper"

class ExistingDataMigrationTest < ActionDispatch::IntegrationTest
  def setup
    # This test verifies that existing production data works with the new system
    @level = Level.find_or_create_by(name: "レベル1") { |l| l.value = 1 }
    @clinic_level = Level.find_or_create_by(name: "クリニック") { |l| l.value = 10 }
    
    @user = User.create!(
      name: "中村結衣",  # Same as production data
      email: "nakamura_#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      phone: "090-#{rand(1000..9999)}-#{rand(1000..9999)}",
      level: @level,
      status: "active"
    )
    
    @purchase = Purchase.create!(
      user: @user,
      purchased_at: 1.day.ago,
      payment_type: "cash",
      status: "paid"
    )
    
    # Create existing reservation exactly like production data
    @existing_reservation = ClinicReservation.create!(
      user: @user,
      purchase: @purchase,
      clinic_id: nil,  # Production data has nil clinic_id
      treatment_methods: '["幹細胞培養上清液「歯髄・脂肪・臍帯」お申込みの方：静脈注射（腕）"]',
      preferred_date_1: Date.parse("2025-12-24"),
      preferred_time_1: "11:00-12:00",
      preferred_date_2: nil,
      preferred_time_2: nil,
      preferred_date_3: nil,
      preferred_time_3: nil,
      status: ClinicReservation::PENDING
    )
  end

  test "existing production data can be read and processed" do
    # Verify existing data matches production format
    assert_not_nil @existing_reservation.id
    assert_not_nil @existing_reservation.purchase_id
    assert_equal "中村結衣", @existing_reservation.user.name
    assert_nil @existing_reservation.clinic_id
    assert_equal "11:00-12:00", @existing_reservation.preferred_time_1
    assert_nil @existing_reservation.preferred_time_2
    assert_nil @existing_reservation.preferred_time_3
    assert @existing_reservation.pending?
    
    # Verify treatment methods parsing works
    methods = @existing_reservation.treatment_methods_array
    assert_equal 1, methods.length
    assert_includes methods, "幹細胞培養上清液「歯髄・脂肪・臍帯」お申込みの方：静脈注射（腕）"
  end

  test "existing data can be migrated to new clinic system" do
    # Create a clinic user (like existing clinic users in production)
    clinic_user = User.create!(
      name: "GINZA中央クリニック",
      email: "ginza_#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      phone: "090-#{rand(1000..9999)}-#{rand(1000..9999)}",
      level: @clinic_level
    )
    
    # Create new clinic record for this user
    clinic = Clinic.create!(
      user: clinic_user,
      name: clinic_user.name,
      is_active: true
    )
    
    # Set up business hours
    clinic.clinic_business_hours.create!(
      weekday: 1, # Monday
      start_time: "10:00",
      end_time: "18:00"
    )
    
    # Migrate existing reservation to new clinic system
    @existing_reservation.update!(clinic: clinic)
    
    # Verify migration worked
    assert_equal clinic, @existing_reservation.clinic
    assert_equal clinic_user, @existing_reservation.clinic.user
    assert_equal "GINZA中央クリニック", @existing_reservation.clinic.name
    
    # Verify all other data is preserved
    assert_equal "11:00-12:00", @existing_reservation.preferred_time_1
    assert @existing_reservation.pending?
    assert_equal @user, @existing_reservation.user
    assert_equal @purchase, @existing_reservation.purchase
  end

  test "existing data works with availability service after migration" do
    # Set up clinic system
    clinic_user = User.create!(
      name: "テストクリニック",
      email: "clinic_#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      phone: "090-#{rand(1000..9999)}-#{rand(1000..9999)}",
      level: @clinic_level
    )
    
    clinic = Clinic.create!(
      user: clinic_user,
      name: clinic_user.name,
      is_active: true
    )
    
    # Set up business hours that include the existing reservation time
    weekday = @existing_reservation.preferred_date_1.wday
    clinic.clinic_business_hours.create!(
      weekday: weekday,
      start_time: "09:00",
      end_time: "18:00"
    )
    
    # Migrate existing reservation
    @existing_reservation.update!(clinic: clinic)
    
    # Test availability service with existing data
    service = Clinic::AvailabilityService.new(clinic)
    available_slots = service.available_slots(@existing_reservation.preferred_date_1)
    
    # The existing time slot should be available (since it's not confirmed yet)
    assert_includes available_slots, @existing_reservation.preferred_time_1
    
    # Confirm the existing reservation
    @existing_reservation.update!(
      status: ClinicReservation::CONFIRMED,
      confirmed_date: @existing_reservation.preferred_date_1,
      confirmed_time: @existing_reservation.preferred_time_1
    )
    
    # Now the slot should be unavailable
    available_slots_after = service.available_slots(@existing_reservation.preferred_date_1)
    assert_not_includes available_slots_after, @existing_reservation.preferred_time_1
  end

  test "existing data validation still works after system upgrade" do
    # Test that existing validation rules still apply
    invalid_reservation = ClinicReservation.new(
      user: @user,
      purchase: @purchase,
      clinic_id: nil  # This should still be allowed (optional)
    )
    
    # Should fail validation for missing required fields
    assert_not invalid_reservation.valid?
    assert_includes invalid_reservation.errors[:treatment_methods], "を入力してください"
    assert_includes invalid_reservation.errors[:preferred_date_1], "を入力してください"
    assert_includes invalid_reservation.errors[:preferred_time_1], "を入力してください"
    
    # But clinic_id being nil should not cause validation error
    assert_not_includes invalid_reservation.errors.attribute_names, :clinic_id
  end

  test "existing status constants and methods remain unchanged" do
    # Verify that existing status system still works
    assert_equal 0, ClinicReservation::PENDING
    assert_equal 1, ClinicReservation::CONFIRMED
    assert_equal 2, ClinicReservation::COMPLETED
    assert_equal 3, ClinicReservation::CANCELLED
    
    # Test status methods with existing data
    assert @existing_reservation.pending?
    assert_not @existing_reservation.confirmed?
    assert_equal '予約申込中', @existing_reservation.status_name
    
    # Test status transitions
    @existing_reservation.update!(status: ClinicReservation::CONFIRMED)
    assert @existing_reservation.confirmed?
    assert_equal '予約確定', @existing_reservation.status_name
  end
end