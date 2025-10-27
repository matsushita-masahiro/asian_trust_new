require "application_system_test_case"

class PostalCodeErrorHandlingTest < ApplicationSystemTestCase
  fixtures :users, :levels, :addresses
  
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "不正な郵便番号形式でのエラーハンドリング" do
    visit user_path(@user)
    click_button "編集"
    
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    
    # 文字が含まれる郵便番号
    postal_code_field.fill_in with: "123-abcd"
    sleep 1
    
    # エラーメッセージが表示されることを確認
    error_element = find('.postal-code-error', visible: true)
    assert error_element.visible?, "文字入力時のエラーメッセージが表示されていません"
  end

  test "短すぎる郵便番号でのエラーハンドリング" do
    visit user_path(@user)
    click_button "編集"
    
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    
    # 5桁の郵便番号
    postal_code_field.fill_in with: "12345"
    sleep 1
    
    # 7桁未満の場合は処理されないことを確認（エラーも表示されない）
    error_element = find('.postal-code-error', visible: false)
    assert_not error_element.visible?, "短い郵便番号で不要なエラーが表示されています"
  end

  test "長すぎる郵便番号でのエラーハンドリング" do
    visit user_path(@user)
    click_button "編集"
    
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    
    # 8桁の郵便番号
    postal_code_field.fill_in with: "12345678"
    sleep 1
    
    # エラーメッセージが表示されることを確認
    error_element = find('.postal-code-error', visible: true)
    assert error_element.visible?, "長すぎる郵便番号でのエラーメッセージが表示されていません"
    
    error_message = error_element.find('.error-message').text
    assert_includes error_message, "7桁以内", "適切なエラーメッセージが表示されていません"
  end

  test "存在しない郵便番号でのエラーハンドリング" do
    visit user_path(@user)
    click_button "編集"
    
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    
    # 存在しない郵便番号
    postal_code_field.fill_in with: "9999999"
    sleep 2 # API呼び出し完了を待つ
    
    # エラーメッセージが表示されることを確認
    error_element = find('.postal-code-error', visible: true)
    assert error_element.visible?, "存在しない郵便番号でのエラーメッセージが表示されていません"
    
    error_message = error_element.find('.error-message').text
    assert_includes error_message, "該当する住所が見つかりませんでした", "適切なエラーメッセージが表示されていません"
  end

  test "ネットワークエラーシミュレーション" do
    visit user_path(@user)
    click_button "編集"
    
    # JavaScriptでネットワークエラーをシミュレート
    page.execute_script(<<~JS)
      // fetchをモックしてネットワークエラーをシミュレート
      const originalFetch = window.fetch;
      window.fetch = function() {
        return Promise.reject(new Error('Network error'));
      };
    JS)
    
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    postal_code_field.fill_in with: "1000001"
    sleep 2
    
    # ネットワークエラーメッセージが表示されることを確認
    error_element = find('.postal-code-error', visible: true)
    assert error_element.visible?, "ネットワークエラー時のメッセージが表示されていません"
    
    # fetchを元に戻す
    page.execute_script("window.fetch = arguments[0];", "originalFetch")
  end

  test "API タイムアウトエラーハンドリング" do
    visit user_path(@user)
    click_button "編集"
    
    # JavaScriptでタイムアウトをシミュレート
    page.execute_script(<<~JS)
      // fetchをモックしてタイムアウトをシミュレート
      window.fetch = function() {
        return new Promise((resolve, reject) => {
          setTimeout(() => {
            reject(new Error('Request timeout'));
          }, 100);
        });
      };
    JS)
    
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    postal_code_field.fill_in with: "1000001"
    sleep 3
    
    # タイムアウトエラーメッセージが表示されることを確認
    error_element = find('.postal-code-error', visible: true)
    assert error_element.visible?, "タイムアウトエラー時のメッセージが表示されていません"
  end

  test "連続入力でのデバウンス機能テスト" do
    visit user_path(@user)
    click_button "編集"
    
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    address_field = find('textarea[data-address-type="registration"][name*="address"]')
    
    # 連続して文字を入力
    postal_code_field.fill_in with: "1"
    sleep 0.1
    postal_code_field.fill_in with: "10"
    sleep 0.1
    postal_code_field.fill_in with: "100"
    sleep 0.1
    postal_code_field.fill_in with: "1000"
    sleep 0.1
    postal_code_field.fill_in with: "10000"
    sleep 0.1
    postal_code_field.fill_in with: "100000"
    sleep 0.1
    postal_code_field.fill_in with: "1000001"
    
    # デバウンス期間を待つ
    sleep 1
    
    # 最終的に正しい住所が取得されることを確認
    assert_not_empty address_field.value, "デバウンス後に住所が取得されていません"
    assert_includes address_field.value, "東京都", "デバウンス機能が正常に動作していません"
  end

  test "フォーカス時のエラークリア機能テスト" do
    visit user_path(@user)
    click_button "編集"
    
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    
    # まずエラーを発生させる
    postal_code_field.fill_in with: "0000000"
    sleep 1
    
    # エラーが表示されることを確認
    error_element = find('.postal-code-error', visible: true)
    assert error_element.visible?, "エラーメッセージが表示されていません"
    
    # フィールドにフォーカスを当てる
    postal_code_field.click
    
    # エラーがクリアされることを確認
    sleep 0.5
    assert_not find('.postal-code-error').visible?, "フォーカス時にエラーがクリアされていません"
  end

  test "不正なハイフン位置でのエラーハンドリング" do
    visit user_path(@user)
    click_button "編集"
    
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    
    # 不正なハイフン位置の郵便番号
    postal_code_field.fill_in with: "12-34567"
    sleep 1
    
    # エラーメッセージが表示されることを確認
    error_element = find('.postal-code-error', visible: true)
    assert error_element.visible?, "不正なハイフン位置でのエラーメッセージが表示されていません"
    
    error_message = error_element.find('.error-message').text
    assert_includes error_message, "形式が正しくありません", "適切なエラーメッセージが表示されていません"
  end

  test "複数のハイフンでのエラーハンドリング" do
    visit user_path(@user)
    click_button "編集"
    
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    
    # 複数のハイフンが含まれる郵便番号
    postal_code_field.fill_in with: "12-34-567"
    sleep 1
    
    # エラーメッセージが表示されることを確認
    error_element = find('.postal-code-error', visible: true)
    assert error_element.visible?, "複数ハイフンでのエラーメッセージが表示されていません"
  end

  test "空文字入力時の処理テスト" do
    visit user_path(@user)
    click_button "編集"
    
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    address_field = find('textarea[data-address-type="registration"][name*="address"]')
    
    # まず有効な郵便番号を入力
    postal_code_field.fill_in with: "1000001"
    sleep 1
    
    # 住所が入力されることを確認
    assert_not_empty address_field.value, "住所が入力されていません"
    
    # 郵便番号を空にする
    postal_code_field.fill_in with: ""
    sleep 0.5
    
    # エラーが表示されないことを確認
    error_element = find('.postal-code-error', visible: false)
    assert_not error_element.visible?, "空文字入力時に不要なエラーが表示されています"
  end

  private

  def sign_in_as(user)
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "password"
    click_button "ログイン"
  end
end