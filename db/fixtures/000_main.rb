# # メインのfixtureファイル - 実行順序を管理

# puts "🚀 Starting fixture data creation..."
# puts "⚠️  This will delete all existing user and purchase data!"

# # 実行順序の説明
# puts "\n📋 Execution Order:"
# puts "  1. Level data (from seeds.rb or existing fixtures)"
# puts "  2. Product data (from existing fixtures)"
# puts "  3. User data cleanup and creation (from CSV)"
# puts "  4. Clinic data creation"
# puts "  5. Purchase data creation (based on CSV users)"

# puts "\n🔄 Starting data creation process..."

# # クリニックデータを作成
# load Rails.root.join('db', 'fixtures', 'clinics.rb')

# # 統計情報を表示
# puts "\n📊 Database Statistics:"
# puts "  Levels: #{Level.count}"
# puts "  Products: #{Product.count}"
# puts "  Users: #{User.count}"
# puts "  Purchases: #{Purchase.count}"
# puts "  Purchase Items: #{PurchaseItem.count}"

# # ユーザーレベル別統計
# if User.count > 0
#   puts "\n👥 Users by Level:"
#   User.joins(:level).group('levels.name').count.each do |level_name, count|
#     puts "    #{level_name}: #{count}"
#   end
# end