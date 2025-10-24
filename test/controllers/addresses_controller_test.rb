require "test_helper"

class AddressesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @admin_user = users(:one) # Assuming user one is admin, adjust if needed
    @address = addresses(:registration_address_one)
    
    # Make user one an admin for testing
    @admin_user.update!(admin: true) if @admin_user.respond_to?(:admin=)
  end

  # CRUD操作テスト - CREATE
  test "should create address when authenticated as owner" do
    sign_in @user
    
    assert_difference('Address.count') do
      post addresses_path, params: {
        user_id: @user.id,
        address: {
          address_type: 'shipping',
          postal_code: '123-4567',
          address: '新しい配送先住所'
        }
      }, as: :json
    end
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data['success']
    assert_equal '住所を保存しました', response_data['message']
    assert_equal 'shipping', response_data['address']['address_type']
    assert_equal '配送先住所', response_data['address']['address_type_label']
  end

  test "should update existing address when creating with same address_type" do
    sign_in @user
    
    # 既存の登録住所を更新
    assert_no_difference('Address.count') do
      post addresses_path, params: {
        user_id: @user.id,
        address: {
          address_type: 'registration',
          postal_code: '999-8888',
          address: '更新された登録住所'
        }
      }, as: :json
    end
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data['success']
    
    @address.reload
    assert_equal '999-8888', @address.postal_code
    assert_equal '更新された登録住所', @address.address
  end

  test "should not create address with invalid data" do
    sign_in @user
    
    assert_no_difference('Address.count') do
      post addresses_path, params: {
        user_id: @user.id,
        address: {
          address_type: 'registration',
          postal_code: 'invalid',
          address: '' # 必須項目が空
        }
      }, as: :json
    end
    
    assert_response :unprocessable_entity
    response_data = JSON.parse(response.body)
    assert_not response_data['success']
    assert_includes response_data['errors'], "Address can't be blank"
  end

  # CRUD操作テスト - UPDATE
  test "should update address when authenticated as owner" do
    sign_in @user
    
    patch address_path(@address), params: {
      address: {
        postal_code: '555-6666',
        address: '更新された住所'
      }
    }, as: :json
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data['success']
    assert_equal '住所を更新しました', response_data['message']
    
    @address.reload
    assert_equal '555-6666', @address.postal_code
    assert_equal '更新された住所', @address.address
  end

  test "should not update address with invalid data" do
    sign_in @user
    
    patch address_path(@address), params: {
      address: {
        address: '' # 必須項目を空にする
      }
    }, as: :json
    
    assert_response :unprocessable_entity
    response_data = JSON.parse(response.body)
    assert_not response_data['success']
    assert_includes response_data['errors'], "Address can't be blank"
  end

  # CRUD操作テスト - DELETE
  test "should destroy address when authenticated as owner" do
    sign_in @user
    
    assert_difference('Address.count', -1) do
      delete address_path(@address), as: :json
    end
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data['success']
    assert_equal '住所を削除しました', response_data['message']
  end

  # 権限制御テスト
  test "should not allow unauthenticated access" do
    post addresses_path, params: {
      user_id: @user.id,
      address: { address_type: 'registration', address: 'test' }
    }, as: :json
    
    assert_response :unauthorized
  end

  test "should not allow access to other user's addresses" do
    sign_in @other_user
    
    post addresses_path, params: {
      user_id: @user.id,
      address: { address_type: 'registration', address: 'test' }
    }, as: :json
    
    assert_response :forbidden
    response_data = JSON.parse(response.body)
    assert_not response_data['success']
    assert_equal '権限がありません', response_data['message']
  end

  test "should not allow updating other user's addresses" do
    sign_in @other_user
    
    patch address_path(@address), params: {
      address: { address: 'unauthorized update' }
    }, as: :json
    
    assert_response :forbidden
  end

  test "should not allow deleting other user's addresses" do
    sign_in @other_user
    
    delete address_path(@address), as: :json
    
    assert_response :forbidden
  end

  test "should allow admin to manage any user's addresses" do
    skip "Admin functionality test - implement if admin user exists" unless @admin_user.respond_to?(:admin?) && @admin_user.admin?
    
    sign_in @admin_user
    
    # 他のユーザーの住所を作成
    post addresses_path, params: {
      user_id: @other_user.id,
      address: {
        address_type: 'registration',
        address: '管理者が作成した住所'
      }
    }, as: :json
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data['success']
  end

  # Ajax レスポンステスト
  test "should return JSON response for create" do
    sign_in @user
    
    post addresses_path, params: {
      user_id: @user.id,
      address: {
        address_type: 'shipping',
        postal_code: '123-4567',
        address: 'テスト住所'
      }
    }, as: :json
    
    assert_response :success
    assert_equal 'application/json; charset=utf-8', response.content_type
    
    response_data = JSON.parse(response.body)
    assert_includes response_data.keys, 'success'
    assert_includes response_data.keys, 'message'
    assert_includes response_data.keys, 'address'
    
    address_data = response_data['address']
    assert_includes address_data.keys, 'id'
    assert_includes address_data.keys, 'address_type'
    assert_includes address_data.keys, 'address_type_label'
    assert_includes address_data.keys, 'postal_code'
    assert_includes address_data.keys, 'address'
    assert_includes address_data.keys, 'formatted_address'
  end

  test "should return JSON response for update" do
    sign_in @user
    
    patch address_path(@address), params: {
      address: {
        postal_code: '999-8888',
        address: '更新テスト住所'
      }
    }, as: :json
    
    assert_response :success
    assert_equal 'application/json; charset=utf-8', response.content_type
    
    response_data = JSON.parse(response.body)
    assert response_data['success']
    assert_equal '住所を更新しました', response_data['message']
  end

  test "should return JSON response for destroy" do
    sign_in @user
    
    delete address_path(@address), as: :json
    
    assert_response :success
    assert_equal 'application/json; charset=utf-8', response.content_type
    
    response_data = JSON.parse(response.body)
    assert response_data['success']
    assert_equal '住所を削除しました', response_data['message']
  end

  # エラーハンドリングテスト
  test "should handle address not found" do
    sign_in @user
    
    patch address_path(99999), params: {
      address: { address: 'test' }
    }, as: :json
    
    assert_response :not_found
    response_data = JSON.parse(response.body)
    assert_not response_data['success']
    assert_equal '住所が見つかりません', response_data['message']
  end

  test "should handle user not found" do
    sign_in @user
    
    post addresses_path, params: {
      user_id: 99999,
      address: { address_type: 'registration', address: 'test' }
    }, as: :json
    
    assert_response :not_found
    response_data = JSON.parse(response.body)
    assert_not response_data['success']
    assert_equal 'ユーザーが見つかりません', response_data['message']
  end

  private

  def sign_in(user)
    # Devise test helper for signing in users
    # Adjust this method based on your authentication setup
    post user_session_path, params: {
      user: {
        email: user.email,
        password: 'password' # Adjust based on your test fixtures
      }
    }
  end
end