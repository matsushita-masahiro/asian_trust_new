require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get orders_index_url
    assert_response :success
  end

  test "should get products" do
    get orders_products_url
    assert_response :success
  end

  test "should get cart" do
    get orders_cart_url
    assert_response :success
  end

  test "should get checkout" do
    get orders_checkout_url
    assert_response :success
  end
end
