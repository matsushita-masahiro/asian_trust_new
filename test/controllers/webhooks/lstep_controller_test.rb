require "test_helper"

class Webhooks::LstepControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get webhooks_lstep_create_url
    assert_response :success
  end
end
