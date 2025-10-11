# CSVベースのユーザーデータに対応した購入データなどのテストデータを作成

class OtherFixture
  def self.create_test_data
    puts "🛒 Creating purchase and other test data..."
    
    # 既存の購入データをクリーンアップ
    puts "🧹 Cleaning up existing purchase data..."
    adapter = ActiveRecord::Base.connection.adapter_name
    
    if adapter == "SQLite"
      ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF")
      PurchaseItem.delete_all
      Purchase.delete_all
      ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='purchases'")
      ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='purchase_items'")
      ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON")
    else
      PurchaseItem.delete_all
      Purchase.delete_all
    end
    
    puts "✅ Purchase data cleanup completed"
    
    # 商品を取得（fixturesから）
    product = Product.find_by(name: "骨髄幹細胞培培養上清液")
    if product.nil?
      puts "⚠️  Product '骨髄幹細胞培培養上清液' not found. Make sure to run fixtures first."
      puts "    Run: rails db:seed_fu"
      return
    end
    
    # CSVから作成されたユーザーを取得
    csv_users = User.where("lstep_user_id LIKE 'lstep_csv_%'")
    
    if csv_users.empty?
      puts "⚠️  No CSV users found. Make sure to run user fixtures first."
      return
    end
    
    puts "📊 Found #{csv_users.count} CSV users for test data creation"
    
    # 特約代理店レベルのユーザーを取得
    special_agents = csv_users.joins(:level).where(levels: { name: "特約代理店" })
    
    # アドバイザーレベルのユーザーを取得
    advisors = csv_users.joins(:level).where(levels: { name: "アドバイザー" })
    
    # サロン・クリニックレベルのユーザーを取得
    salon_clinic_users = csv_users.joins(:level).where(levels: { name: ["サロン", "クリニック"] })
    
    purchase_count = 0
    
    # 特約代理店の購入データを作成
    special_agents.limit(5).each_with_index do |user, i|
      # 2025年8月の購入データ
      purchase = Purchase.create!(
        user_id: user.id,
        buyer_id: user.id,
        purchased_at: "2025-08-#{8 + i} 10:#{30 + (i * 15)}:00"
      )
      
      PurchaseItem.create!(
        purchase: purchase,
        product: product,
        quantity: 30 + (i * 10),
        unit_price: 50000,
        seller_price: 45000  # 特約代理店の購入価格
      )
      
      purchase_count += 1
      
      # 2025年9月の購入データも追加
      purchase_sep = Purchase.create!(
        user_id: user.id,
        buyer_id: user.id,
        purchased_at: "2025-09-#{10 + i} 14:#{20 + (i * 10)}:00"
      )
      
      PurchaseItem.create!(
        purchase: purchase_sep,
        product: product,
        quantity: 25 + (i * 5),
        unit_price: 50000,
        seller_price: 45000
      )
      
      purchase_count += 1
    end
    
    puts "✅ Created purchase data for #{special_agents.limit(5).count} special agents"
    
    # アドバイザーの購入データを作成
    advisors.limit(10).each_with_index do |user, i|
      # 2025年9月の購入データ
      purchase = Purchase.create!(
        user_id: user.id,
        buyer_id: user.id,
        purchased_at: "2025-09-#{15 + i} 11:#{30 + (i * 5)}:00"
      )
      
      PurchaseItem.create!(
        purchase: purchase,
        product: product,
        quantity: 8 + (i * 2),
        unit_price: 50000,
        seller_price: 49000  # アドバイザーの購入価格
      )
      
      purchase_count += 1
    end
    
    puts "✅ Created purchase data for #{advisors.limit(10).count} advisors"
    
    # サロン・クリニックの購入データを作成
    salon_clinic_users.limit(8).each_with_index do |user, i|
      # 2025年9月の購入データ
      purchase = Purchase.create!(
        user_id: user.id,
        buyer_id: user.id,
        purchased_at: "2025-09-#{20 + i} 13:#{45 + (i * 8)}:00"
      )
      
      PurchaseItem.create!(
        purchase: purchase,
        product: product,
        quantity: 3 + i,
        unit_price: 50000,
        seller_price: 50000  # サロン・クリニックの購入価格
      )
      
      purchase_count += 1
    end
    
    puts "✅ Created purchase data for #{salon_clinic_users.limit(8).count} salon/clinic users"
    
    # 追加の購入データ（10月分）
    # より多様な購入パターンを作成
    csv_users.limit(15).each_with_index do |user, i|
      next if i % 3 != 0  # 3人に1人だけ10月の購入データを作成
      
      purchase = Purchase.create!(
        user_id: user.id,
        buyer_id: user.id,
        purchased_at: "2025-10-#{5 + (i / 3)} 16:#{10 + (i * 7)}:00"
      )
      
      # レベルに応じて価格を調整
      seller_price = case user.level.name
                    when "特約代理店"
                      45000
                    when "代理店"
                      47000
                    when "アドバイザー"
                      49000
                    else
                      50000
                    end
      
      PurchaseItem.create!(
        purchase: purchase,
        product: product,
        quantity: 5 + (i % 8),
        unit_price: 50000,
        seller_price: seller_price
      )
      
      purchase_count += 1
    end
    
    puts "✅ Created additional October purchase data"
    
    puts "🛒 Test data creation completed! Created #{purchase_count} purchases total"
    
    # 統計情報を表示
    puts "\n📈 Purchase Statistics:"
    puts "  Total Purchases: #{Purchase.count}"
    puts "  Total Purchase Items: #{PurchaseItem.count}"
    puts "  Users with Purchases: #{Purchase.distinct.count(:user_id)}"
    
    # レベル別購入統計
    level_stats = Purchase.joins(user: :level)
                         .group('levels.name')
                         .count
    
    puts "  Purchases by Level:"
    level_stats.each do |level_name, count|
      puts "    #{level_name}: #{count}"
    end
  end
end

# テストデータを作成
OtherFixture.create_test_data