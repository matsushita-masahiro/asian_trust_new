# puts "🔄 Seeding started......"

# # データをクリーンアップ
# adapter = ActiveRecord::Base.connection.adapter_name

# if adapter == "SQLite"
#   ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF")
#   PurchaseItem.delete_all
#   Purchase.delete_all
#   User.delete_all
#   ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='users'")
#   ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='purchases'")
#   ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='purchase_items'")
#   ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON")
# else
#   PurchaseItem.delete_all
#   Purchase.delete_all
#   User.delete_all
# end

# # Levelデータを作成または取得
# level_data = [
#   { name: "アジアビジネストラスト", value: 0 },
#   { name: "総代理店", value: 1 },
#   { name: "代理店", value: 2 },
#   { name: "アドバイザー", value: 3 },
#   { name: "サロン", value: 4 },
#   { name: "クリニック", value: 5 },
#   { name: "お客様", value: 6 }
# ]

# level_data.each do |data|
#   Level.find_or_create_by(name: data[:name]) do |level|
#     level.value = data[:value]
#   end
# end

# # Levelデータを取得（nameで検索）
# levels = Level.all.index_by(&:name)

# # デバッグ用：作成されたLevelを確認
# puts "Created levels:"
# levels.each do |name, level|
#   puts "  #{name}: #{level.id} (value: #{level.value})"
# end

# # エラーハンドリング
# if levels["アジアビジネストラスト"].nil?
#   puts "❌ Error: 'アジアビジネストラスト' level not found!"
#   exit 1
# end

# puts "✅ Level data setup completed!"
# puts "📝 Note: User data will be created from fixtures/user.rb"
# puts "📝 Note: Purchase data will be created from fixtures/other.rb"

# puts "✅ Seeding completed!"