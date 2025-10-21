puts "🔄 Production seeding started......"

# 本番環境では既存データを削除せず、不足データのみ追加

# Levelデータを作成または取得
level_data = [
  { name: "アジアビジネストラスト", value: 0 },
  { name: "総代理店", value: 1 },
  { name: "代理店", value: 2 },
  { name: "アドバイザー", value: 3 },
  { name: "サロン", value: 4 },
  { name: "クリニック", value: 5 },
  { name: "お客様", value: 6 }
]

level_data.each do |data|
  Level.find_or_create_by(name: data[:name]) do |level|
    level.value = data[:value]
  end
end

# Levelデータを取得（nameで検索）
levels = Level.all.index_by(&:name)

# デバッグ用：作成されたLevelを確認
puts "Available levels:"
levels.each do |name, level|
  puts "  #{name}: #{level.id} (value: #{level.value})"
end

# Productデータを作成（既存チェック）
product = Product.find_or_create_by(name: "再生医療製品") do |p|
  p.base_price = 50000
  p.unit_quantity = 1
  p.unit_label = "本"
  p.description = "再生医療用製品"
end

puts "Product: #{product.name} (ID: #{product.id})"

# ProductPriceデータを作成（各レベルの価格設定）
price_data = [
  { level_name: "アジアビジネストラスト", price: 40000 },
  { level_name: "総代理店", price: 45000 },
  { level_name: "代理店", price: 47000 },
  { level_name: "アドバイザー", price: 49000 },
  { level_name: "サロン", price: 50000 },
  { level_name: "クリニック", price: 50000 },
  { level_name: "お客様", price: 50000 }
]

price_data.each do |data|
  level = levels[data[:level_name]]
  if level
    existing_price = ProductPrice.find_by(product: product, level: level)
    if existing_price
      puts "  Price already exists for #{data[:level_name]}: #{existing_price.price}円"
    else
      ProductPrice.create!(product: product, level: level, price: data[:price])
      puts "  Created price for #{data[:level_name]}: #{data[:price]}円"
    end
  end
end

# 管理者ユーザーの確認・作成
company = User.find_by(email: "info@abt-saisei.com")
if company.nil?
  # 最大IDを取得して安全なIDを設定
  max_id = User.maximum(:id) || 0
  next_id = max_id + 1
  
  company = User.create!(
    id: next_id,
    name: "アジアビジネストラスト",
    email: "info@abt-saisei.com",
    password: "password",
    level_id: levels["アジアビジネストラスト"].id,
    lstep_user_id: "lstep_#{format('%04d', next_id)}",
    confirmed_at: Time.current
  )
  puts "✅ Created admin user: #{company.name}"
else
  puts "✅ Admin user already exists: #{company.name}"
end

# 既存ユーザー数を確認
existing_users_count = User.count
puts "📊 Current users count: #{existing_users_count}"

# テストユーザーが不足している場合のみ追加
if existing_users_count < 10
  puts "🔄 Adding test users..."
  
  # 安全なID範囲を計算
  max_id = User.maximum(:id) || 0
  user_id_seq = max_id + 1
  lstep_id_seq = max_id + 1
  
  # 特約代理店を少数追加
  2.times do |i|
    email = "special_agent_prod#{i + 1}@example.com"
    unless User.exists?(email: email)
      User.create!(
        id: user_id_seq,
        name: "総代理店#{i + 1}",
        email: email,
        password: "password",
        level_id: levels["総代理店"].id,
        referred_by_id: company.id,
        lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
        confirmed_at: Time.current
      )
      user_id_seq += 1
      lstep_id_seq += 1
      puts "  ✅ Created: 総代理店#{i + 1}"
    end
  end
  
  # 代理店を少数追加
  2.times do |i|
    email = "agent_prod#{i + 1}@example.com"
    unless User.exists?(email: email)
      User.create!(
        id: user_id_seq,
        name: "代理店#{i + 1}",
        email: email,
        password: "password",
        level_id: levels["代理店"].id,
        referred_by_id: company.id,
        lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
        confirmed_at: Time.current
      )
      user_id_seq += 1
      lstep_id_seq += 1
      puts "  ✅ Created: 代理店#{i + 1}"
    end
  end
else
  puts "📝 Sufficient users exist, skipping user creation"
end

puts "✅ Production seeding completed!"
puts "📊 Final stats:"
puts "  Users: #{User.count}"
puts "  Levels: #{Level.count}"
puts "  Products: #{Product.count}"
puts "  Product Prices: #{ProductPrice.count}"