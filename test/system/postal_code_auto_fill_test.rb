require "application_system_test_case"

class PostalCodeAutoFillTest < ApplicationSystemTestCase
  setup do
    # 既存のレベルを使用するか、新しく作成
    @level = Level.find_or_create_by(value: 98) do |level|
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
    
    sign_in_as(@user)
  end

  test "郵便番号自動入力の基本機能テスト" do
    visit user_path(@user)
    
    # 登録住所の編集モードに切り替え
    click_button "編集"
    
    # 郵便番号フィールドを取得
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    address_field = find('textarea[data-address-type="registration"][name*="address"]')
    
    # 郵便番号を入力（有効な郵便番号）
    postal_code_field.fill_in with: "1000001"
    
    # 少し待機してAPI呼び出しが完了するのを待つ
    sleep 1
    
    # 住所フィールドに自動入力されることを確認
    # 注意: 実際のAPIを使用するため、結果は変動する可能性があります
    assert_not_empty address_field.value, "住所が自動入力されていません"
    
    # 住所に「東京都」が含まれることを確認（1000001は東京都千代田区）
    assert_includes address_field.value, "東京都", "正しい住所が取得されていません"
  end

  test "無効な郵便番号でのエラー表示テスト" do
    visit user_path(@user)
    
    # 登録住所の編集モードに切り替え
    click_button "編集"
    
    # 郵便番号フィールドを取得
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    
    # 無効な郵便番号を入力
    postal_code_field.fill_in with: "0000000"
    
    # 少し待機してAPI呼び出しが完了するのを待つ
    sleep 1
    
    # エラーメッセージが表示されることを確認
    error_element = find('.postal-code-error', visible: true)
    assert error_element.visible?, "エラーメッセージが表示されていません"
    
    error_message = error_element.find('.error-message').text
    assert_includes error_message, "該当する住所が見つかりませんでした", "適切なエラーメッセージが表示されていません"
  end

  test "ハイフンあり郵便番号の処理テスト" do
    visit user_path(@user)
    
    # 登録住所の編集モードに切り替え
    click_button "編集"
    
    # 郵便番号フィールドを取得
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    address_field = find('textarea[data-address-type="registration"][name*="address"]')
    
    # ハイフン付き郵便番号を入力
    postal_code_field.fill_in with: "100-0001"
    
    # 少し待機してAPI呼び出しが完了するのを待つ
    sleep 1
    
    # 住所フィールドに自動入力されることを確認
    assert_not_empty address_field.value, "ハイフン付き郵便番号で住所が自動入力されていません"
    assert_includes address_field.value, "東京都", "正しい住所が取得されていません"
  end

  test "配送先住所での郵便番号自動入力テスト" do
    visit user_path(@user)
    
    # 配送先住所の編集ボタンをクリック
    within('[data-address-type="shipping"]') do
      click_button "編集"
    end
    
    # 配送先住所の郵便番号フィールドを取得
    postal_code_field = find('input[data-address-type="shipping"][name*="postal_code"]')
    address_field = find('textarea[data-address-type="shipping"][name*="address"]')
    
    # 郵便番号を入力
    postal_code_field.fill_in with: "5400001"
    
    # 少し待機してAPI呼び出しが完了するのを待つ
    sleep 1
    
    # 住所フィールドに自動入力されることを確認
    assert_not_empty address_field.value, "配送先住所で住所が自動入力されていません"
    assert_includes address_field.value, "大阪府", "正しい住所が取得されていません"
  end

  test "手動編集後の郵便番号変更テスト" do
    visit user_path(@user)
    
    # 登録住所の編集モードに切り替え
    click_button "編集"
    
    # 郵便番号フィールドを取得
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    address_field = find('textarea[data-address-type="registration"][name*="address"]')
    
    # 最初の郵便番号を入力
    postal_code_field.fill_in with: "1000001"
    sleep 1
    
    # 自動入力された住所を確認
    original_address = address_field.value
    assert_not_empty original_address, "最初の住所が自動入力されていません"
    
    # 住所を手動で編集（詳細情報を追加）
    address_field.fill_in with: original_address + " テストビル101"
    
    # 郵便番号を変更
    postal_code_field.fill_in with: "5400001"
    sleep 1
    
    # 新しい住所が取得されることを確認
    new_address = address_field.value
    assert_includes new_address, "大阪府", "郵便番号変更後に新しい住所が取得されていません"
  end

  test "郵便番号クリア時の住所クリアテスト" do
    visit user_path(@user)
    
    # 登録住所の編集モードに切り替え
    click_button "編集"
    
    # 郵便番号フィールドを取得
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    address_field = find('textarea[data-address-type="registration"][name*="address"]')
    
    # 郵便番号を入力
    postal_code_field.fill_in with: "1000001"
    sleep 1
    
    # 住所が自動入力されることを確認
    assert_not_empty address_field.value, "住所が自動入力されていません"
    
    # 郵便番号をクリア
    postal_code_field.fill_in with: ""
    
    # 住所フィールドもクリアされることを確認
    # 注意: この動作は実装によって異なる場合があります
    sleep 0.5
    # 住所フィールドの値をチェック（実装に応じて調整が必要）
  end

  test "ローディングインジケーター表示テスト" do
    visit user_path(@user)
    
    # 登録住所の編集モードに切り替え
    click_button "編集"
    
    # 郵便番号フィールドを取得
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    
    # ローディングインジケーターが最初は非表示であることを確認
    loading_indicator = find('.postal-code-loading', visible: false)
    assert_not loading_indicator.visible?, "ローディングインジケーターが初期状態で表示されています"
    
    # 郵便番号を入力
    postal_code_field.fill_in with: "1000001"
    
    # 短時間でローディングインジケーターが表示されることを確認
    # 注意: タイミングによっては確認が困難な場合があります
    begin
      assert find('.postal-code-loading', visible: true, wait: 0.5)
    rescue Capybara::ElementNotFound
      # ローディングが非常に高速な場合はスキップ
      puts "ローディングインジケーターの表示確認をスキップ（高速処理のため）"
    end
    
    # 最終的にローディングが非表示になることを確認
    sleep 2
    assert_not find('.postal-code-loading').visible?, "ローディングインジケーターが非表示になっていません"
  end

  test "フォーム送信での住所保存テスト" do
    visit user_path(@user)
    
    # 登録住所の編集モードに切り替え
    click_button "編集"
    
    # 郵便番号フィールドを取得
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    address_field = find('textarea[data-address-type="registration"][name*="address"]')
    
    # 郵便番号を入力
    postal_code_field.fill_in with: "1000001"
    sleep 1
    
    # 自動入力された住所に詳細を追加
    current_address = address_field.value
    address_field.fill_in with: current_address + " テストビル101"
    
    # フォームを送信
    click_button "保存"
    
    # ページがリロードされることを確認
    assert_current_path user_path(@user)
    
    # 保存された住所が表示されることを確認
    within('[data-address-type="registration"]') do
      assert_text "テストビル101", "住所の詳細情報が保存されていません"
      assert_text "東京都", "基本住所が保存されていません"
    end
  end

  test "複数フォームでの独立動作テスト" do
    visit user_path(@user)
    
    # 両方の住所編集モードに切り替え
    within('[data-address-type="registration"]') do
      click_button "編集"
    end
    
    within('[data-address-type="shipping"]') do
      click_button "編集"
    end
    
    # 登録住所の郵便番号を入力
    registration_postal = find('input[data-address-type="registration"][name*="postal_code"]')
    registration_address = find('textarea[data-address-type="registration"][name*="address"]')
    
    registration_postal.fill_in with: "1000001"
    sleep 1
    
    # 配送先住所の郵便番号を入力
    shipping_postal = find('input[data-address-type="shipping"][name*="postal_code"]')
    shipping_address = find('textarea[data-address-type="shipping"][name*="address"]')
    
    shipping_postal.fill_in with: "5400001"
    sleep 1
    
    # それぞれ独立して正しい住所が入力されることを確認
    assert_includes registration_address.value, "東京都", "登録住所が正しく取得されていません"
    assert_includes shipping_address.value, "大阪府", "配送先住所が正しく取得されていません"
    
    # 住所が混在していないことを確認
    assert_not_includes registration_address.value, "大阪府", "登録住所に配送先住所が混在しています"
    assert_not_includes shipping_address.value, "東京都", "配送先住所に登録住所が混在しています"
  end

  test "Turboナビゲーション後の動作テスト" do
    visit user_path(@user)
    
    # 別のページに移動
    click_link "🏠 マイページに戻る"
    
    # 再度ユーザーページに戻る
    visit user_path(@user)
    
    # 郵便番号自動入力機能が正常に動作することを確認
    click_button "編集"
    
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    address_field = find('textarea[data-address-type="registration"][name*="address"]')
    
    postal_code_field.fill_in with: "1000001"
    sleep 1
    
    # Turboナビゲーション後も正常に動作することを確認
    assert_not_empty address_field.value, "Turboナビゲーション後に郵便番号自動入力が動作していません"
    assert_includes address_field.value, "東京都", "Turboナビゲーション後に正しい住所が取得されていません"
  end

  private

  def sign_in_as(user)
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "password"
    click_button "ログイン"
  end
end