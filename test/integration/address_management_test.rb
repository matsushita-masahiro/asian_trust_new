require "test_helper"

class AddressManagementTest < ActionDispatch::IntegrationTest
  def setup
    # テストデータを直接作成
    @level = Level.find_or_create_by!(value: 1) { |l| l.name = "テストレベル" }
    
    @user = User.create!(
      name: "テストユーザー#{rand(1000)}",
      email: "test#{rand(1000)}@example.com",
      password: "password",
      confirmed_at: Time.current,
      level_id: @level.id,
      admin: false
    )
    
    @admin_user = User.create!(
      name: "管理者ユーザー#{rand(1000)}",
      email: "admin#{rand(1000)}@example.com",
      password: "password",
      confirmed_at: Time.current,
      level_id: @level.id,
      admin: true
    )
    
    @other_user = User.create!(
      name: "他のユーザー#{rand(1000)}",
      email: "other#{rand(1000)}@example.com",
      password: "password",
      confirmed_at: Time.current,
      level_id: @level.id,
      admin: false
    )
  end

  def teardown
    # テストデータをクリーンアップ
    Address.destroy_all
    InvoiceBase.destroy_all
    User.destroy_all
  end

  # 住所登録フローテスト
  test "user can register and manage addresses through complete flow" do
    sign_in_as(@user)
    
    # ユーザー詳細ページにアクセス
    get user_path(@user)
    assert_response :success
    
    # 登録住所を作成
    post user_addresses_path(@user), params: {
      address: {
        address_type: 'registration',
        postal_code: '1234567', # ハイフンなしで入力
        address: '東京都渋谷区渋谷1-1-1 テストビル101'
      }
    }, as: :json
    
    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data['success']
    
    # 郵便番号が自動フォーマットされることを確認
    registration_address = @user.reload.registration_address
    assert_equal '123-4567', registration_address.postal_code
    assert_equal '東京都渋谷区渋谷1-1-1 テストビル101', registration_address.address
    
    # 配送先住所を作成
    post user_addresses_path(@user), params: {
      address: {
        address_type: 'shipping',
        postal_code: '987-6543',
        address: '大阪府大阪市北区梅田2-2-2 配送ビル202'
      }
    }, as: :json
    
    assert_response :success
    
    # 両方の住所が正しく保存されることを確認
    @user.reload
    assert_not_nil @user.registration_address
    assert_not_nil @user.shipping_address
    assert_equal 2, @user.addresses.count
    
    # 住所を更新
    patch user_address_path(@user, @user.registration_address), params: {
      address: {
        postal_code: '111-2222',
        address: '更新された登録住所'
      }
    }, as: :json
    
    assert_response :success
    
    # 更新が反映されることを確認
    @user.registration_address.reload
    assert_equal '111-2222', @user.registration_address.postal_code
    assert_equal '更新された登録住所', @user.registration_address.address
    
    # 住所を削除
    delete user_address_path(@user, @user.shipping_address), as: :json
    assert_response :success
    
    # 削除が反映されることを確認
    @user.reload
    assert_nil @user.shipping_address
    assert_equal 1, @user.addresses.count
  end

  test "address uniqueness is enforced per user and address type" do
    sign_in_as(@user)
    
    # 最初の登録住所を作成
    post user_addresses_path(@user), params: {
      address: {
        address_type: 'registration',
        address: '最初の登録住所'
      }
    }, as: :json
    
    assert_response :success
    first_address_id = JSON.parse(response.body)['address']['id']
    
    # 同じタイプの住所を再度作成（既存住所が更新される）
    post user_addresses_path(@user), params: {
      address: {
        address_type: 'registration',
        address: '更新された登録住所'
      }
    }, as: :json
    
    assert_response :success
    updated_address_id = JSON.parse(response.body)['address']['id']
    
    # 同じIDであることを確認（新規作成ではなく更新）
    assert_equal first_address_id, updated_address_id
    
    # 住所が更新されていることを確認
    @user.reload
    assert_equal '更新された登録住所', @user.registration_address.address
    assert_equal 1, @user.addresses.count
  end

  # 管理画面での住所管理テスト
  test "admin can manage user addresses through admin interface" do
    skip "Admin functionality test - implement if admin interface exists" unless @admin_user.admin?
    
    sign_in_as(@admin_user)
    
    # 管理者として他のユーザーの住所を作成
    post admin_user_addresses_path(@other_user), params: {
      address: {
        address_type: 'registration',
        address: '管理者が作成した住所'
      }
    }, as: :json
    
    assert_response :success
    
    # 住所が正しく作成されることを確認
    @other_user.reload
    assert_not_nil @other_user.registration_address
    assert_equal '管理者が作成した住所', @other_user.registration_address.address
    
    # 管理者として住所を更新
    patch admin_user_address_path(@other_user, @other_user.registration_address), params: {
      address: {
        address: '管理者が更新した住所'
      }
    }, as: :json
    
    assert_response :success
    
    # 更新が反映されることを確認
    @other_user.registration_address.reload
    assert_equal '管理者が更新した住所', @other_user.registration_address.address
  end

  test "non-admin users cannot access other users' addresses" do
    sign_in_as(@user)
    
    # 他のユーザーの住所を作成しようとする
    post user_addresses_path(@other_user), params: {
      address: {
        address_type: 'registration',
        address: '不正アクセス'
      }
    }, as: :json
    
    assert_response :forbidden
    
    # 住所が作成されていないことを確認
    @other_user.reload
    assert_nil @other_user.registration_address
  end

  # データ移行テスト
  test "backward compatibility with existing invoice_base addresses" do
    # invoice_baseに住所がある場合のテスト
    if @user.respond_to?(:invoice_base) && @user.invoice_base
      # 既存のinvoice_base住所を設定
      @user.invoice_base.update!(address: '既存のinvoice_base住所') if @user.invoice_base.respond_to?(:address=)
      
      # 登録住所がない場合、primary_addressはinvoice_baseから取得
      @user.registration_address&.destroy
      assert_equal '既存のinvoice_base住所', @user.primary_address
      
      # 新しい登録住所を作成
      sign_in_as(@user)
      post user_addresses_path(@user), params: {
        address: {
          address_type: 'registration',
          address: '新しい登録住所'
        }
      }, as: :json
      
      assert_response :success
      
      # primary_addressが新しい登録住所を返すことを確認
      @user.reload
      assert_equal '新しい登録住所', @user.primary_address
    else
      skip "invoice_base not available for backward compatibility test"
    end
  end

  test "address validation works in complete flow" do
    sign_in_as(@user)
    
    # 無効な郵便番号で住所作成を試行
    post user_addresses_path(@user), params: {
      address: {
        address_type: 'registration',
        postal_code: 'invalid-postal-code',
        address: 'テスト住所'
      }
    }, as: :json
    
    assert_response :unprocessable_entity
    response_data = JSON.parse(response.body)
    assert_not response_data['success']
    assert_includes response_data['errors'].join, 'invalid'
    
    # 住所が作成されていないことを確認
    @user.reload
    assert_nil @user.registration_address
    
    # 有効なデータで再試行
    post user_addresses_path(@user), params: {
      address: {
        address_type: 'registration',
        postal_code: '123-4567',
        address: 'テスト住所'
      }
    }, as: :json
    
    assert_response :success
    
    # 住所が正しく作成されることを確認
    @user.reload
    assert_not_nil @user.registration_address
    assert_equal '123-4567', @user.registration_address.postal_code
  end

  test "postal code formatting works in integration flow" do
    sign_in_as(@user)
    
    # ハイフンなしの郵便番号で住所を作成
    post user_addresses_path(@user), params: {
      address: {
        address_type: 'registration',
        postal_code: '1234567',
        address: 'フォーマットテスト住所'
      }
    }, as: :json
    
    assert_response :success
    
    # 郵便番号が自動的にフォーマットされることを確認
    @user.reload
    assert_equal '123-4567', @user.registration_address.postal_code
    
    # レスポンスでもフォーマットされた郵便番号が返されることを確認
    response_data = JSON.parse(response.body)
    assert_equal '123-4567', response_data['address']['postal_code']
  end

  private

  def sign_in_as(user)
    # Devise test helper for signing in users
    post user_session_path, params: {
      user: {
        email: user.email,
        password: 'password'
      }
    }
    follow_redirect! if response.redirect?
  end
end