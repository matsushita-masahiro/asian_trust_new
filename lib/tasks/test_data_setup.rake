namespace :test_data do
  desc "移行テスト用のサンプルデータを作成"
  task create_sample_data: :environment do
    puts "移行テスト用のサンプルデータを作成します..."
    
    # デフォルトレベルを取得
    default_level = Level.first || Level.create!(name: 'テストレベル', value: 1)
    
    # テスト用ユーザーを作成
    user1 = User.find_or_create_by(email: 'test1@example.com') do |u|
      u.name = 'テストユーザー1'
      u.password = 'password123'
      u.password_confirmation = 'password123'
      u.confirmed_at = Time.current
      u.level_id = default_level.id
    end
    
    user2 = User.find_or_create_by(email: 'test2@example.com') do |u|
      u.name = 'テストユーザー2'
      u.password = 'password123'
      u.password_confirmation = 'password123'
      u.confirmed_at = Time.current
      u.level_id = default_level.id
    end
    
    user3 = User.find_or_create_by(email: 'test3@example.com') do |u|
      u.name = 'テストユーザー3（住所なし）'
      u.password = 'password123'
      u.password_confirmation = 'password123'
      u.confirmed_at = Time.current
      u.level_id = default_level.id
    end
    
    # テスト用InvoiceBaseを作成
    InvoiceBase.find_or_create_by(user: user1) do |ib|
      ib.company_name = 'テスト会社1'
      ib.postal_code = '1000001'
      ib.address = '東京都千代田区千代田1-1-1'
      ib.email = 'test1@example.com'
    end
    
    InvoiceBase.find_or_create_by(user: user2) do |ib|
      ib.company_name = 'テスト会社2'
      ib.postal_code = '5400001'
      ib.address = '大阪府大阪市中央区城見1-1-1'
      ib.email = 'test2@example.com'
    end
    
    # 住所なしのInvoiceBase
    InvoiceBase.find_or_create_by(user: user3) do |ib|
      ib.company_name = 'テスト会社3'
      ib.email = 'test3@example.com'
      # 住所情報は意図的に空にする
    end
    
    puts "サンプルデータ作成完了:"
    puts "- ユーザー数: #{User.count}"
    puts "- InvoiceBase数: #{InvoiceBase.count}"
    puts "- 住所ありInvoiceBase: #{InvoiceBase.where.not(address: [nil, '']).count}"
  end
  
  desc "テストデータをクリーンアップ"
  task cleanup: :environment do
    puts "テストデータをクリーンアップします..."
    
    # テスト用データを削除
    User.where(email: ['test1@example.com', 'test2@example.com', 'test3@example.com']).destroy_all
    
    puts "クリーンアップ完了"
  end
end