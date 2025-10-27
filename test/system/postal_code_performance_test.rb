require "application_system_test_case"

class PostalCodePerformanceTest < ApplicationSystemTestCase
  fixtures :users, :levels, :addresses
  
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "キャッシュ機能のテスト" do
    visit user_path(@user)
    click_button "編集"
    
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    address_field = find('textarea[data-address-type="registration"][name*="address"]')
    
    # 最初の郵便番号入力（APIから取得）
    start_time = Time.current
    postal_code_field.fill_in with: "1000001"
    sleep 1
    first_response_time = Time.current - start_time
    
    first_address = address_field.value
    assert_not_empty first_address, "最初の住所取得に失敗しました"
    
    # 住所をクリア
    address_field.fill_in with: ""
    
    # 同じ郵便番号を再入力（キャッシュから取得）
    start_time = Time.current
    postal_code_field.fill_in with: "1000001"
    sleep 0.5 # キャッシュからの取得は高速のはず
    second_response_time = Time.current - start_time
    
    second_address = address_field.value
    assert_not_empty second_address, "キャッシュからの住所取得に失敗しました"
    
    # 同じ住所が取得されることを確認
    assert_equal first_address, second_address, "キャッシュから取得した住所が異なります"
    
    # キャッシュからの取得の方が高速であることを確認（参考値）
    puts "最初の取得時間: #{first_response_time}秒"
    puts "キャッシュからの取得時間: #{second_response_time}秒"
  end

  test "デバウンス機能のパフォーマンステスト" do
    visit user_path(@user)
    click_button "編集"
    
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    
    # API呼び出し回数をカウントするためのJavaScriptを注入
    page.execute_script(<<~JS)
      window.apiCallCount = 0;
      const originalFetch = window.fetch;
      window.fetch = function(...args) {
        window.apiCallCount++;
        return originalFetch.apply(this, args);
      };
    JS)
    
    # 連続して文字を入力（デバウンス機能により最後の入力のみAPI呼び出しされるはず）
    "1000001".chars.each_with_index do |char, index|
      postal_code_field.fill_in with: "1000001"[0..index]
      sleep 0.1
    end
    
    # デバウンス期間を待つ
    sleep 1
    
    # API呼び出し回数を確認
    api_call_count = page.evaluate_script("window.apiCallCount")
    
    # デバウンス機能により、API呼び出し回数が制限されていることを確認
    assert api_call_count <= 2, "デバウンス機能が正常に動作していません。API呼び出し回数: #{api_call_count}"
    
    puts "API呼び出し回数: #{api_call_count}"
  end

  test "複数フィールドでの独立したパフォーマンステスト" do
    visit user_path(@user)
    
    # 両方の住所編集モードに切り替え
    within('[data-address-type="registration"]') do
      click_button "編集"
    end
    
    within('[data-address-type="shipping"]') do
      click_button "編集"
    end
    
    registration_postal = find('input[data-address-type="registration"][name*="postal_code"]')
    registration_address = find('textarea[data-address-type="registration"][name*="address"]')
    shipping_postal = find('input[data-address-type="shipping"][name*="postal_code"]')
    shipping_address = find('textarea[data-address-type="shipping"][name*="address"]')
    
    # 同時に異なる郵便番号を入力
    start_time = Time.current
    
    registration_postal.fill_in with: "1000001"
    shipping_postal.fill_in with: "5400001"
    
    sleep 2 # 両方のAPI呼び出し完了を待つ
    
    total_time = Time.current - start_time
    
    # 両方の住所が正しく取得されることを確認
    assert_not_empty registration_address.value, "登録住所が取得されていません"
    assert_not_empty shipping_address.value, "配送先住所が取得されていません"
    
    assert_includes registration_address.value, "東京都", "登録住所が正しくありません"
    assert_includes shipping_address.value, "大阪府", "配送先住所が正しくありません"
    
    puts "複数フィールド同時処理時間: #{total_time}秒"
  end

  test "大量データ入力でのメモリ使用量テスト" do
    visit user_path(@user)
    click_button "編集"
    
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    
    # メモリ使用量を監視するJavaScriptを注入
    page.execute_script(<<~JS)
      window.memoryTestResults = [];
      
      function checkMemory() {
        if (performance.memory) {
          return {
            used: performance.memory.usedJSHeapSize,
            total: performance.memory.totalJSHeapSize,
            limit: performance.memory.jsHeapSizeLimit
          };
        }
        return null;
      }
      
      window.initialMemory = checkMemory();
    JS)
    
    # 複数の郵便番号を順次入力してキャッシュを蓄積
    postal_codes = ["1000001", "5400001", "4600001", "8100001", "9800001"]
    
    postal_codes.each do |postal_code|
      postal_code_field.fill_in with: postal_code
      sleep 1
      
      # メモリ使用量を記録
      page.execute_script(<<~JS)
        const memory = checkMemory();
        if (memory) {
          window.memoryTestResults.push({
            postalCode: '#{postal_code}',
            memory: memory
          });
        }
      JS)
    end
    
    # 最終的なメモリ使用量を確認
    memory_results = page.evaluate_script("window.memoryTestResults")
    initial_memory = page.evaluate_script("window.initialMemory")
    
    if memory_results && initial_memory
      puts "初期メモリ使用量: #{initial_memory['used']} bytes"
      memory_results.each do |result|
        puts "#{result['postalCode']}: #{result['memory']['used']} bytes"
      end
      
      # メモリリークがないことを確認（大幅な増加がないこと）
      final_memory = memory_results.last['memory']['used']
      memory_increase = final_memory - initial_memory['used']
      
      # メモリ増加が合理的な範囲内であることを確認（1MB以下）
      assert memory_increase < 1_000_000, "メモリ使用量が異常に増加しています: #{memory_increase} bytes"
    else
      puts "メモリ監視機能が利用できません（Chrome以外のブラウザ）"
    end
  end

  test "レスポンス時間の測定テスト" do
    visit user_path(@user)
    click_button "編集"
    
    postal_code_field = find('input[data-address-type="registration"][name*="postal_code"]')
    address_field = find('textarea[data-address-type="registration"][name*="address"]')
    
    # レスポンス時間を測定するJavaScriptを注入
    page.execute_script(<<~JS)
      window.responseTimeResults = [];
      
      // PostalCodeAutoFillのfetchAddressメソッドをフック
      document.addEventListener('postalCodeAutoFill:addressUpdated', function(event) {
        const endTime = performance.now();
        if (window.startTime) {
          const responseTime = endTime - window.startTime;
          window.responseTimeResults.push({
            postalCode: event.detail.addressData.zipcode,
            responseTime: responseTime
          });
        }
      });
    JS)
    
    # 複数の郵便番号でレスポンス時間を測定
    test_postal_codes = ["1000001", "5400001", "4600001"]
    
    test_postal_codes.each do |postal_code|
      # 測定開始
      page.execute_script("window.startTime = performance.now();")
      
      postal_code_field.fill_in with: postal_code
      sleep 2 # API呼び出し完了を待つ
      
      # 住所が取得されることを確認
      assert_not_empty address_field.value, "#{postal_code}の住所が取得されていません"
      
      # 次のテストのために住所をクリア
      address_field.fill_in with: ""
    end
    
    # レスポンス時間の結果を確認
    response_results = page.evaluate_script("window.responseTimeResults")
    
    if response_results && response_results.any?
      response_results.each do |result|
        puts "#{result['postalCode']}: #{result['responseTime'].round(2)}ms"
        
        # レスポンス時間が合理的な範囲内であることを確認（10秒以下）
        assert result['responseTime'] < 10000, "#{result['postalCode']}のレスポンス時間が長すぎます: #{result['responseTime']}ms"
      end
      
      # 平均レスポンス時間を計算
      average_time = response_results.sum { |r| r['responseTime'] } / response_results.length
      puts "平均レスポンス時間: #{average_time.round(2)}ms"
    else
      puts "レスポンス時間の測定に失敗しました"
    end
  end

  test "同時リクエスト制限のテスト" do
    visit user_path(@user)
    
    # 両方の住所編集モードに切り替え
    within('[data-address-type="registration"]') do
      click_button "編集"
    end
    
    within('[data-address-type="shipping"]') do
      click_button "編集"
    end
    
    registration_postal = find('input[data-address-type="registration"][name*="postal_code"]')
    shipping_postal = find('input[data-address-type="shipping"][name*="postal_code"]')
    
    # API呼び出し回数を監視
    page.execute_script(<<~JS)
      window.simultaneousApiCalls = 0;
      window.maxSimultaneousCalls = 0;
      
      const originalFetch = window.fetch;
      window.fetch = function(...args) {
        window.simultaneousApiCalls++;
        window.maxSimultaneousCalls = Math.max(window.maxSimultaneousCalls, window.simultaneousApiCalls);
        
        return originalFetch.apply(this, args).finally(() => {
          window.simultaneousApiCalls--;
        });
      };
    JS)
    
    # 同時に複数の郵便番号を入力
    registration_postal.fill_in with: "1000001"
    shipping_postal.fill_in with: "5400001"
    
    sleep 2
    
    # 同時API呼び出し数を確認
    max_calls = page.evaluate_script("window.maxSimultaneousCalls")
    puts "最大同時API呼び出し数: #{max_calls}"
    
    # 適切に制限されていることを確認（通常は2以下）
    assert max_calls <= 3, "同時API呼び出し数が多すぎます: #{max_calls}"
  end

  private

  def sign_in_as(user)
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "password"
    click_button "ログイン"
  end
end