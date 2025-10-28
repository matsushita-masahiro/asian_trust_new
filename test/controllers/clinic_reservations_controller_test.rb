require "test_helper"

class ClinicReservationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get clinic_reservations_new_url
    assert_response :success
  end

  test "should get create" do
    get clinic_reservations_create_url
    assert_response :success
  end

  test "should get show" do
    get clinic_reservations_show_url
    assert_response :success
  end

  test "should get index" do
    get clinic_reservations_index_url
    assert_response :success
  end
end
