require "test_helper"

class Admin::ClinicReservationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_clinic_reservations_index_url
    assert_response :success
  end

  test "should get show" do
    get admin_clinic_reservations_show_url
    assert_response :success
  end

  test "should get edit" do
    get admin_clinic_reservations_edit_url
    assert_response :success
  end

  test "should get update" do
    get admin_clinic_reservations_update_url
    assert_response :success
  end
end
