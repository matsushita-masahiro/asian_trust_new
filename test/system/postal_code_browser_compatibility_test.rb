require "application_system_test_case"

class PostalCodeBrowserCompatibilityTest < ApplicationSystemTestCase
  fixtures :users, :levels, :addresses
  
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "基本的なJavaScript機能の互換性テスト" do
    visit user_path(@user)
    click_button "編集"
    
    # 必要なJavaScript機能が利用可能かチェック
    js_features_available = page.evaluate_script(<<~JS)
      const features = {
        fetch: typeof fetch !== 'undefined',
        promise: typeof Promise !== 'undefined',
        map: typeof Map !== 'undefined',
        setTimeout: typeof setTimeout !== 'undefined',
        addEventListener: typeof document.addEventListener !== 'undefined',
        querySelector: typeof document.querySelector !== 'undefined',
        customEvent: typeof CustomEvent !== 'undefined',
        asyncAwait: (function() {
          try {
            eval('(async function() {})');
            return true;
          } catch (e) {
            return false;
          }
        })()
      };
      
      return features;
    JS)
    
    # 必要な機能がすべて利用可能であることを確認
    assert js_features_available['fetch'], "fetch APIが利用できません"
    assert js_features_available['promise'], "Promise が利用できません"
    assert js_features_available['map'], "Map が利用できません"
    assert js_features_available['setTimeout'], "setTimeout が利用できません"
    assert js_features_available['addEventListener'], "addEventListener が利用できません"
    assert js_features_available['querySelector'], "querySelector が利用できません"
    assert js_features_available['customEvent'], "CustomEvent が利用できません"
    assert js_features_available['asyncAwait'], "async/await が利用できません"
    
    puts "JavaScript機能互換性チェック完了"
    js_features_available.each do |feature, available|
      puts "  #{feature}: #{available ? '✓' : '✗'}"
    end
  end

  test "DOM操作の互換性テスト" do
    visit user_path(@user)
    click_button "編集"
    
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    
    # DOM操作の互換性をテスト
    dom_compatibility = page.evaluate_script(<<~JS)
      const field = document.querySelector('input[data-address-type="registration"][name*="postal_code"]');
      
      const tests = {
        elementFound: !!field,
        valueProperty: field && typeof field.value === 'string',
        addEventListener: field && typeof field.addEventListener === 'function',
        classList: field && field.classList && typeof field.classList.add === 'function',
        style: field && field.style && typeof field.style.borderColor === 'string',
        dataset: field && field.dataset && typeof field.dataset.addressType === 'string',
        parentNode: field && !!field.parentNode,
        insertBefore: field && field.parentNode && typeof field.parentNode.insertBefore === 'function'
      };
      
      return tests;
    JS)
    
    # DOM操作機能が利用可能であることを確認
    assert dom_compatibility['elementFound'], "要素が見つかりません"
    assert dom_compatibility['valueProperty'], "value プロパティが利用できません"
    assert dom_compatibility['addEventListener'], "addEventListener が利用できません"
    assert dom_compatibility['classList'], "classList が利用できません"
    assert dom_compatibility['style'], "style プロパティが利用できません"
    assert dom_compatibility['dataset'], "dataset が利用できません"
    assert dom_compatibility['parentNode'], "parentNode が利用できません"
    assert dom_compatibility['insertBefore'], "insertBefore が利用できません"
    
    puts "DOM操作互換性チェック完了"
  end

  test "イベントハンドリングの互換性テスト" do
    visit user_path(@user)
    click_button "編集"
    
    # イベントハンドリングの互換性をテスト
    event_compatibility = page.evaluate_script(<<~JS)
      const field = document.querySelector('input[data-address-type="registration"][name*="postal_code"]');
      let eventFired = false;
      
      // イベントリスナーを追加
      if (field) {
        field.addEventListener('input', function() {
          eventFired = true;
        });
        
        // イベントを発火
        const event = new Event('input', { bubbles: true });
        field.dispatchEvent(event);
      }
      
      return {
        eventListenerAdded: !!field,
        eventFired: eventFired,
        customEventSupported: typeof CustomEvent !== 'undefined',
        eventBubbling: true // 基本的にサポートされている
      };
    JS)
    
    assert event_compatibility['eventListenerAdded'], "イベントリスナーが追加できません"
    assert event_compatibility['eventFired'], "イベントが発火しません"
    assert event_compatibility['customEventSupported'], "CustomEvent がサポートされていません"
    
    puts "イベントハンドリング互換性チェック完了"
  end

  test "CSS スタイル操作の互換性テスト" do
    visit user_path(@user)
    click_button "編集"
    
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    
    # CSS操作の互換性をテスト
    css_compatibility = page.evaluate_script(<<~JS)
      const field = document.querySelector('input[data-address-type="registration"][name*="postal_code"]');
      
      if (!field) return { error: 'Field not found' };
      
      // スタイル操作をテスト
      const originalBorder = field.style.borderColor;
      field.style.borderColor = 'red';
      const redBorderSet = field.style.borderColor === 'red';
      field.style.borderColor = originalBorder;
      
      // クラス操作をテスト
      field.classList.add('test-class');
      const classAdded = field.classList.contains('test-class');
      field.classList.remove('test-class');
      
      return {
        styleProperty: typeof field.style === 'object',
        borderColorChange: redBorderSet,
        classListAdd: classAdded,
        classListRemove: !field.classList.contains('test-class'),
        display: typeof field.style.display === 'string'
      };
    JS)
    
    assert css_compatibility['styleProperty'], "style プロパティが利用できません"
    assert css_compatibility['borderColorChange'], "borderColor の変更ができません"
    assert css_compatibility['classListAdd'], "classList.add が動作しません"
    assert css_compatibility['classListRemove'], "classList.remove が動作しません"
    assert css_compatibility['display'], "display プロパティが利用できません"
    
    puts "CSS操作互換性チェック完了"
  end

  test "非同期処理の互換性テスト" do
    visit user_path(@user)
    click_button "編集"
    
    # 非同期処理の互換性をテスト
    async_compatibility = page.evaluate_script(<<~JS)
      let promiseResolved = false;
      let timeoutExecuted = false;
      
      // Promise のテスト
      const promise = new Promise((resolve) => {
        setTimeout(() => {
          promiseResolved = true;
          resolve();
        }, 100);
      });
      
      // setTimeout のテスト
      setTimeout(() => {
        timeoutExecuted = true;
      }, 50);
      
      // 結果を確認するために少し待つ
      return new Promise((resolve) => {
        setTimeout(() => {
          resolve({
            promiseSupported: typeof Promise !== 'undefined',
            timeoutSupported: typeof setTimeout !== 'undefined',
            promiseResolved: promiseResolved,
            timeoutExecuted: timeoutExecuted
          });
        }, 200);
      });
    JS)
    
    assert async_compatibility['promiseSupported'], "Promise がサポートされていません"
    assert async_compatibility['timeoutSupported'], "setTimeout がサポートされていません"
    assert async_compatibility['promiseResolved'], "Promise が解決されません"
    assert async_compatibility['timeoutExecuted'], "setTimeout が実行されません"
    
    puts "非同期処理互換性チェック完了"
  end

  test "実際の郵便番号入力での動作確認" do
    visit user_path(@user)
    click_button "編集"
    
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    address_field = find('textarea[data-address-type="registration"][name*="address"]')
    
    # 実際の郵便番号を入力して動作確認
    postal_code_field.fill_in with: "1000001"
    sleep 2
    
    # 住所が正しく取得されることを確認
    assert_not_empty address_field.value, "住所が取得されていません"
    assert_includes address_field.value, "東京都", "正しい住所が取得されていません"
    
    # エラーが発生していないことを確認
    error_element = find('.postal-code-error', visible: false)
    assert_not error_element.visible?, "予期しないエラーが発生しています"
    
    puts "実際の動作確認完了: #{address_field.value}"
  end

  test "ユーザーエージェント情報の取得" do
    visit user_path(@user)
    
    # ブラウザ情報を取得
    browser_info = page.evaluate_script(<<~JS)
      return {
        userAgent: navigator.userAgent,
        platform: navigator.platform,
        language: navigator.language,
        cookieEnabled: navigator.cookieEnabled,
        onLine: navigator.onLine,
        javaEnabled: navigator.javaEnabled ? navigator.javaEnabled() : false
      };
    JS)
    
    puts "ブラウザ情報:"
    puts "  User Agent: #{browser_info['userAgent']}"
    puts "  Platform: #{browser_info['platform']}"
    puts "  Language: #{browser_info['language']}"
    puts "  Cookie Enabled: #{browser_info['cookieEnabled']}"
    puts "  Online: #{browser_info['onLine']}"
    puts "  Java Enabled: #{browser_info['javaEnabled']}"
    
    # 基本的な機能が利用可能であることを確認
    assert browser_info['cookieEnabled'], "Cookie が無効になっています"
    assert browser_info['onLine'], "オフライン状態です"
  end

  test "レスポンシブデザインでの動作確認" do
    # モバイルサイズでの動作確認
    page.driver.browser.manage.window.resize_to(375, 667) # iPhone サイズ
    
    visit user_path(@user)
    click_button "編集"
    
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    address_field = find('textarea[data-address-type="registration"][name*="address"]')
    
    # モバイルサイズでも正常に動作することを確認
    postal_code_field.fill_in with: "1000001"
    sleep 2
    
    assert_not_empty address_field.value, "モバイルサイズで住所が取得されていません"
    assert_includes address_field.value, "東京都", "モバイルサイズで正しい住所が取得されていません"
    
    # デスクトップサイズに戻す
    page.driver.browser.manage.window.resize_to(1400, 1400)
    
    puts "レスポンシブデザイン動作確認完了"
  end

  private

  def sign_in_as(user)
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "password"
    click_button "ログイン"
  end
end