puts "🔄 Seeding started......"

adapter = ActiveRecord::Base.connection.adapter_name

# SQLite環境のみ、外部キー制約を一時無効化
if adapter == "SQLite"
  ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF")
  User.delete_all
  ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='users'")
  ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON")
else
  # PostgreSQL など他の環境では普通に削除
  User.delete_all
end

user_id_seq = 1
lstep_id_seq = 1

# Levelデータを作成または取得
level_data = [
  { name: "アジアビジネストラスト", value: 0 },
  { name: "特約代理店", value: 1 },
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
puts "Created levels:"
levels.each do |name, level|
  puts "  #{name}: #{level.id} (value: #{level.value})"
end

# エラーハンドリング
if levels["アジアビジネストラスト"].nil?
  puts "❌ Error: 'アジアビジネストラスト' level not found!"
  exit 1
end

# Productデータを作成
product = Product.find_or_create_by(name: "再生医療製品") do |p|
  p.base_price = 50000
  p.display_unit = "本"
  p.description = "再生医療用製品"
end

# ProductPriceデータを作成（各レベルの価格設定）
price_data = [
  { level_name: "アジアビジネストラスト", price: 40000 },
  { level_name: "特約代理店", price: 45000 },
  { level_name: "代理店", price: 47000 },
  { level_name: "アドバイザー", price: 49000 },
  { level_name: "サロン", price: 50000 },
  { level_name: "クリニック", price: 50000 },
  { level_name: "お客様", price: 50000 }
]

price_data.each do |data|
  level = levels[data[:level_name]]
  if level
    ProductPrice.find_or_create_by(product: product, level: level) do |pp|
      pp.price = data[:price]
    end
  end
end

# 最上位
company = User.create!(
  id: user_id_seq,
  name: "アジアビジネストラスト",
  email: "info@abt-saisei.com",
  password: "password",
  level_id: levels["アジアビジネストラスト"].id,
  lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
  confirmed_at: Time.current
)
user_id_seq += 1
lstep_id_seq += 1

# 特約代理店（level: 特約代理店）
special_agents = 3.times.map do |i|
  user = User.create!(
    id: user_id_seq,
    name: "特約代理店#{i + 1}",
    email: "special_agent#{i + 1}@example.com",
    password: "password",
    level_id: levels["特約代理店"].id,
    referred_by_id: company.id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1
  user
end

# 代理店
agents = []
special_agents.each_with_index do |parent, i|
  2.times do |j|
    user = User.create!(
      id: user_id_seq,
      name: "代理店#{i + 1}-#{j + 1}",
      email: "agent#{i + 1}-#{j + 1}@example.com",
      password: "password",
      level_id: levels["代理店"].id,
      referred_by_id: parent.id,
      lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
      confirmed_at: Time.current
    )
    user_id_seq += 1
    lstep_id_seq += 1
    agents << user
  end
end

# アドバイザー
advisors = []
agents.each_with_index do |parent, i|
  2.times do |j|
    user = User.create!(
      id: user_id_seq,
      name: "アドバイザー#{i + 1}-#{j + 1}",
      email: "advisor#{i + 1}-#{j + 1}@example.com",
      password: "password",
      level_id: levels["アドバイザー"].id,
      referred_by_id: parent.id,
      lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
      confirmed_at: Time.current
    )
    user_id_seq += 1
    lstep_id_seq += 1
    advisors << user
  end
end

# サロン・クリニック
advisors.each_with_index do |parent, i|
  ["サロン", "クリニック"].each_with_index do |type, _idx|
    User.create!(
      id: user_id_seq,
      name: "#{type}#{i + 1}",
      email: "#{type.downcase}#{i + 1}@example.com",
      password: "password",
      level_id: levels[type].id,
      referred_by_id: parent.id,
      lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
      confirmed_at: Time.current
    )
    user_id_seq += 1
    lstep_id_seq += 1
  end
end

# --- 追加パターン (1) ---
2.times do |i|
  advisor = User.create!(
    id: user_id_seq,
    name: "特約1-アドバイザー#{i + 1}",
    email: "tokuyaku1_advisor#{i + 1}@example.com",
    password: "password",
    level_id: levels["アドバイザー"].id,
    referred_by_id: special_agents[0].id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1

  User.create!(
    id: user_id_seq,
    name: "特約1-サロン#{i + 1}",
    email: "tokuyaku1_salon#{i + 1}@example.com",
    password: "password",
    level_id: levels["サロン"].id,
    referred_by_id: advisor.id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1
end

# --- 追加パターン (2) ---
2.times do |i|
  User.create!(
    id: user_id_seq,
    name: "特約2-サロン#{i + 1}",
    email: "tokuyaku2_salon#{i + 1}@example.com",
    password: "password",
    level_id: levels["サロン"].id,
    referred_by_id: special_agents[1].id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1
end

# --- 追加パターン (3) ---
2.times do |i|
  advisor1 = User.create!(
    id: user_id_seq,
    name: "特約3-アドバイザー#{i + 1}-1",
    email: "tokuyaku3_advisor#{i + 1}_1@example.com",
    password: "password",
    level_id: levels["アドバイザー"].id,
    referred_by_id: special_agents[2].id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1

  advisor2 = User.create!(
    id: user_id_seq,
    name: "特約3-アドバイザー#{i + 1}-2",
    email: "tokuyaku3_advisor#{i + 1}_2@example.com",
    password: "password",
    level_id: levels["アドバイザー"].id,
    referred_by_id: advisor1.id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1

  User.create!(
    id: user_id_seq,
    name: "特約3-サロン#{i + 1}",
    email: "tokuyaku3_salon#{i + 1}@example.com",
    password: "password",
    level_id: levels["サロン"].id,
    referred_by_id: advisor2.id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1
end

# 購入データの作成（新しいデータ構造に対応）
puts "🛒 Creating purchase data..."

# 商品を取得
product = Product.first
if product.nil?
  puts "⚠️  No products found. Skipping purchase data creation."
else
  # 特約代理店1が自分で購入するデータを作成
  special_agent_1 = User.find_by(name: "特約代理店1")
  
  if special_agent_1
    # 2025年8月の購入データ
    purchase = Purchase.create!(
      user_id: special_agent_1.id,        # 仲介者（自分）
      buyer_id: special_agent_1.id,       # 購入者（自分）
      purchased_at: "2025-08-08 10:00:00"
    )
    
    PurchaseItem.create!(
      purchase: purchase,
      product: product,
      quantity: 40,
      unit_price: 50000,
      seller_price: 45000  # 特約代理店の購入価格
    )
    
    puts "✅ Created purchase data for 特約代理店1"
    
    # 他の代理店の購入データも作成
    agents.first(3).each_with_index do |agent, i|
      purchase = Purchase.create!(
        user_id: agent.id,        # 仲介者（自分）
        buyer_id: agent.id,       # 購入者（自分）
        purchased_at: "2025-08-#{10 + i} 14:00:00"
      )
      
      PurchaseItem.create!(
        purchase: purchase,
        product: product,
        quantity: 20 + (i * 5),
        unit_price: 50000,
        seller_price: 47000  # 代理店の購入価格
      )
    end
    
    puts "✅ Created purchase data for agents"
  end
end

puts "✅ Seeding completed!"
