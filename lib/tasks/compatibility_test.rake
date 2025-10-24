namespace :address do
  desc "後方互換性の動作確認テスト"
  task compatibility_test: :environment do
    puts "後方互換性の動作確認テストを開始します..."
    
    # テストユーザーを取得
    user1 = User.find_by(email: 'test1@example.com')
    user2 = User.find_by(email: 'test2@example.com')
    user3 = User.find_by(email: 'test3@example.com')
    
    puts "\n=== テスト1: 住所ありユーザーの後方互換性 ==="
    [user1, user2].each do |user|
      puts "\nユーザー: #{user.name}"
      
      # 既存の方法（invoice_base経由）
      invoice_base_address = user.invoice_base&.address
      invoice_base_postal = user.invoice_base&.postal_code
      
      # 新しい方法（Address経由）
      registration_address = user.registration_address&.address
      registration_postal = user.registration_address&.postal_code
      
      # 後方互換性メソッド
      primary_address = user.primary_address
      primary_postal = user.primary_postal_code
      
      puts "  invoice_base.address: #{invoice_base_address || 'なし'}"
      puts "  registration_address: #{registration_address || 'なし'}"
      puts "  primary_address: #{primary_address || 'なし'}"
      puts "  住所一致: #{invoice_base_address == registration_address ? '✓' : '✗'}"
      puts "  後方互換性: #{primary_address == registration_address ? '✓' : '✗'}"
      
      puts "  invoice_base.postal_code: #{invoice_base_postal || 'なし'}"
      puts "  registration_postal_code: #{registration_postal || 'なし'}"
      puts "  primary_postal_code: #{primary_postal || 'なし'}"
      puts "  郵便番号一致: #{invoice_base_postal == registration_postal ? '✓' : '✗'}"
    end
    
    puts "\n=== テスト2: 住所なしユーザーの後方互換性 ==="
    puts "\nユーザー: #{user3.name}"
    puts "  invoice_base.address: #{user3.invoice_base&.address || 'なし'}"
    puts "  registration_address: #{user3.registration_address&.address || 'なし'}"
    puts "  primary_address: #{user3.primary_address || 'なし'}"
    puts "  後方互換性: #{user3.primary_address.nil? ? '✓' : '✗'}"
    
    puts "\n=== テスト3: 新しい住所を追加した場合の動作 ==="
    # user3に配送先住所を追加
    shipping_address = user3.addresses.create!(
      address_type: 'shipping',
      postal_code: '1500001',
      address: '東京都渋谷区神宮前1-1-1'
    )
    
    puts "\nユーザー: #{user3.name} に配送先住所を追加"
    puts "  shipping_address: #{user3.shipping_address&.address || 'なし'}"
    puts "  primary_address: #{user3.primary_address || 'なし'}"
    puts "  配送先住所のみの場合、primary_addressはinvoice_baseを参照: #{user3.primary_address == user3.invoice_base&.address ? '✓' : '✗'}"
    
    # 登録住所も追加
    registration_address = user3.addresses.create!(
      address_type: 'registration',
      postal_code: '1060032',
      address: '東京都港区六本木1-1-1'
    )
    
    puts "\n登録住所も追加後:"
    puts "  registration_address: #{user3.registration_address&.address || 'なし'}"
    puts "  primary_address: #{user3.primary_address || 'なし'}"
    puts "  登録住所が優先される: #{user3.primary_address == user3.registration_address&.address ? '✓' : '✗'}"
    
    puts "\n=== 後方互換性テスト完了 ==="
  end
end