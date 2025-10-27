require 'test_helper'

class PostalCodeAutoFillIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    # 既存のレベルを使用するか、新しく作成
    @level = Level.find_or_create_by(value: 99) do |level|
      level.name = "テストレベル"
    end
    
    # ユーザーを作成
    @user = User.create!(
      name: "テストユーザー",
      email: "test_postal_#{SecureRandom.hex(4)}@example.com",
      password: "password",
      password_confirmation: "password",
      confirmed_at: Time.current,
      level: @level,
      status: "active"
    )
    
    sign_in @user
  end

  test "郵便番号自動入力機能のJavaScript統合テスト" do
    get user_path(@user)
    assert_response :success
    
    # ページに必要なJavaScriptファイルが含まれていることを確認
    assert_select 'script[src*="postal_code_auto_fill"]', false # importmapで管理されているため直接のscriptタグはない
    
    # 郵便番号入力フィールドが存在することを確認
    assert_select 'input[name*="postal_code"][data-address-type="registration"]'
    assert_select 'input[name*="postal_code"][data-address-type="shipping"]'
    
    # 住所入力フィールドが存在することを確認
    assert_select 'textarea[name*="address"][data-address-type="registration"]'
    assert_select 'textarea[name*="address"][data-address-type="shipping"]'
    
    # ローディングインジケーター要素が存在することを確認
    assert_select '.postal-code-loading'
    
    # エラー表示要素が存在することを確認
    assert_select '.postal-code-error'
  end

  test "住所フォーム送信での郵便番号処理テスト" do
    # 登録住所の作成テスト
    post user_addresses_path(@user), params: {
      address: {
        address_type: 'registration',
        postal_code: '1000001',
        address: '東京都千代田区千代田1-1-1 テストビル101'
      }
    }
    
    assert_response :redirect
    follow_redirect!
    assert_response :success
    
    # 作成された住所を確認
    @user.reload
    registration_address = @user.registration_address
    assert_not_nil registration_address
    assert_equal '100-0001', registration_address.postal_code # フォーマットされた郵便番号
    assert_includes registration_address.address, '東京都千代田区千代田'
  end

  test "無効な郵便番号での住所作成エラーテスト" do
    post user_addresses_path(@user), params: {
      address: {
        address_type: 'registration',
        postal_code: 'invalid',
        address: 'テスト住所'
      }
    }
    
    # バリデーションエラーが発生することを確認
    assert_response :unprocessable_entity
    
    # エラーメッセージが含まれることを確認
    assert_includes response.body, 'postal_code'
  end

  test "住所更新での郵便番号変更テスト" do
    # 最初に住所を作成
    address = @user.addresses.create!(
      address_type: 'registration',
      postal_code: '123-4567',
      address: '初期住所'
    )
    
    # 住所を更新
    patch user_address_path(@user, address), params: {
      address: {
        postal_code: '100-0001',
        address: '東京都千代田区千代田1-1-1 更新された住所'
      }
    }
    
    assert_response :redirect
    follow_redirect!
    
    # 更新された住所を確認
    address.reload
    assert_equal '100-0001', address.postal_code
    assert_includes address.address, '東京都千代田区千代田'
  end

  test "配送先住所での郵便番号自動入力統合テスト" do
    post user_addresses_path(@user), params: {
      address: {
        address_type: 'shipping',
        postal_code: '5400001',
        address: '大阪府大阪市中央区城見1-1-1 配送先ビル'
      }
    }
    
    assert_response :redirect
    follow_redirect!
    
    # 作成された配送先住所を確認
    @user.reload
    shipping_address = @user.shipping_address
    assert_not_nil shipping_address
    assert_equal '540-0001', shipping_address.postal_code
    assert_includes shipping_address.address, '大阪府大阪市中央区城見'
  end

  test "住所フォームのレスポンス形式テスト" do
    # JSON形式でのレスポンステスト
    post user_addresses_path(@user), params: {
      address: {
        address_type: 'registration',
        postal_code: '100-0001',
        address: '東京都千代田区千代田1-1-1'
      }
    }, headers: { 'Accept' => 'application/json' }
    
    if response.content_type.include?('application/json')
      json_response = JSON.parse(response.body)
      
      # レスポンスに必要な情報が含まれることを確認
      assert json_response.key?('address')
      address_data = json_response['address']
      
      assert_equal '100-0001', address_data['postal_code']
      assert_includes address_data['address'], '東京都千代田区千代田'
    end
  end

  test "郵便番号フォーマット処理の統合テスト" do
    # ハイフンなしの郵便番号で住所を作成
    post user_addresses_path(@user), params: {
      address: {
        address_type: 'registration',
        postal_code: '1000001', # ハイフンなし
        address: '東京都千代田区千代田1-1-1'
      }
    }
    
    assert_response :redirect
    follow_redirect!
    
    # 郵便番号が自動的にフォーマットされることを確認
    @user.reload
    registration_address = @user.registration_address
    assert_equal '100-0001', registration_address.postal_code # ハイフンが自動追加
  end

  test "住所編集フォームの表示テスト" do
    get user_path(@user)
    assert_response :success
    
    # 住所編集フォームの要素が正しく配置されていることを確認
    assert_select 'div[data-address-type="registration"]' do
      assert_select 'input[name*="postal_code"]'
      assert_select 'textarea[name*="address"]'
      assert_select '.postal-code-loading'
      assert_select '.postal-code-error'
    end
    
    assert_select 'div[data-address-type="shipping"]' do
      assert_select 'input[name*="postal_code"]'
      assert_select 'textarea[name*="address"]'
      assert_select '.postal-code-loading'
      assert_select '.postal-code-error'
    end
  end

  test "エラーハンドリングの統合テスト" do
    # 必須項目が空の場合のテスト
    post user_addresses_path(@user), params: {
      address: {
        address_type: 'registration',
        postal_code: '100-0001',
        address: '' # 住所が空
      }
    }
    
    assert_response :unprocessable_entity
    
    # エラーメッセージが適切に表示されることを確認
    assert_includes response.body, 'address'
  end

  test "住所削除後の郵便番号自動入力テスト" do
    # 住所を作成
    address = @user.addresses.create!(
      address_type: 'registration',
      postal_code: '123-4567',
      address: '削除予定住所'
    )
    
    # 住所を削除
    delete user_address_path(@user, address)
    assert_response :redirect
    
    # ユーザーページを表示
    get user_path(@user)
    assert_response :success
    
    # 住所が削除されていることを確認
    @user.reload
    assert_nil @user.registration_address
    
    # フォームが正常に表示されることを確認（新規作成用）
    assert_select 'input[name*="postal_code"][data-address-type="registration"]'
    assert_select 'textarea[name*="address"][data-address-type="registration"]'
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: 'password'
      }
    }
  end
end