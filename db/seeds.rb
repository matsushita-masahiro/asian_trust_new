puts "🔄 Seeding started......"

adapter = ActiveRecord::Base.connection.adapter_name

# データを適切な順序で削除（外部キー制約を考慮）
puts "🗑️ Cleaning existing data..."

# 1. 購入関連データを削除
PurchaseItem.delete_all
Purchase.delete_all

# 2. 請求書関連データを削除
Invoice.delete_all

# 3. レベル変更申請を削除
LevelChangeApplication.delete_all

# 4. 紹介招待を削除
ReferralInvitation.delete_all

# 5. ユーザーレベル履歴を削除
UserLevelHistory.delete_all

# 6. カート関連データを削除
CartItem.delete_all
Cart.delete_all

# 7. アクセスログを削除
AccessLog.delete_all

# 8. 最後にユーザーを削除
User.delete_all

# SQLite環境のみ、シーケンスをリセット
if adapter == "SQLite"
  ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='users'")
end

puts "✅ Data cleanup completed"

user_id_seq = 1
lstep_id_seq = 1

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
product1 = Product.find_or_create_by(name: "骨髄幹細胞培培養上清液") do |p|
  p.base_price = 50000
  p.unit_quantity = 1
  p.unit_label = "本"
  p.description = "骨髄幹細胞培培養上清液"
end

product2 = Product.find_or_create_by(name: "歯髄幹細胞培培養上清液") do |p|
  p.base_price = 30000
  p.unit_quantity = 1
  p.unit_label = "本"
  p.description = "歯髄幹細胞培培養上清液"
end

# ProductPriceデータを作成（各レベルの価格設定）
price_data_1 = [
  { level_name: "アジアビジネストラスト", price: 4000 },
  { level_name: "総代理店", price: 36000 },
  { level_name: "代理店", price: 38000 },
  { level_name: "アドバイザー", price: 40000 },
  { level_name: "サロン", price: 50000 },
  { level_name: "クリニック", price: 50000 },
  { level_name: "お客様", price: 50000 }
]

price_data_2 = [
  { level_name: "アジアビジネストラスト", price: 2400 },
  { level_name: "総代理店", price: 21600 },
  { level_name: "代理店", price: 22800 },
  { level_name: "アドバイザー", price: 24000 },
  { level_name: "サロン", price: 30000 },
  { level_name: "クリニック", price: 30000 },
  { level_name: "お客様", price: 30000 }
]

[
  { product: product1, price_data: price_data_1 },
  { product: product2, price_data: price_data_2 }
].each do |product_info|
  product_info[:price_data].each do |data|
    level = levels[data[:level_name]]
    if level
      ProductPrice.find_or_create_by(product: product_info[:product], level: level) do |pp|
        pp.price = data[:price]
      end
    end
  end
end

# 最上位
company = User.create!(
  id: user_id_seq,
  name: "アジアビジネストラスト",
  email: "info@abt-saisei.com",
  password: "111111",
  level_id: levels["アジアビジネストラスト"].id,
  lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
  confirmed_at: Time.current
)
user_id_seq += 1
lstep_id_seq += 1

# 総代理店（level: 総代理店）
special_agent_names = ["田中美咲", "佐藤花音", "山田優香"]
special_agents = special_agent_names.map.with_index do |name, i|
  user = User.create!(
    id: user_id_seq,
    name: name,
    email: "special_agent#{i + 1}@example.com",
    password: "111111",
    level_id: levels["総代理店"].id,
    referred_by_id: company.id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1
  user
end

# 代理店
agent_names = [
  ["鈴木愛美", "高橋彩花"], # 田中美咲の下位
  ["伊藤真由", "渡辺麻衣"], # 佐藤花音の下位
  ["小林沙織", "加藤美穂"]  # 山田優香の下位
]
agents = []
special_agents.each_with_index do |parent, i|
  agent_names[i].each_with_index do |name, j|
    user = User.create!(
      id: user_id_seq,
      name: name,
      email: "agent#{i + 1}-#{j + 1}@example.com",
      password: "111111",
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
advisor_names = [
  ["中村結衣", "林美里"],     # 鈴木愛美の下位
  ["森川桃子", "清水香織"],   # 高橋彩花の下位
  ["石川千夏", "松本優子"],   # 伊藤真由の下位
  ["井上美奈", "木村理恵"],   # 渡辺麻衣の下位
  ["斎藤由美", "橋本恵子"],   # 小林沙織の下位
  ["山口智子", "吉田美和"]    # 加藤美穂の下位
]
advisors = []
agents.each_with_index do |parent, i|
  advisor_names[i].each_with_index do |name, j|
    user = User.create!(
      id: user_id_seq,
      name: name,
      email: "advisor#{i + 1}-#{j + 1}@example.com",
      password: "111111",
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
salon_clinic_names = [
  ["美容サロン花音", "田中クリニック"],   # 中村結衣の下位
  ["エステ美里", "林医院"],             # 林美里の下位
  ["サロン桃花", "森川皮膚科"],         # 森川桃子の下位
  ["ビューティー香織", "清水内科"],     # 清水香織の下位
  ["夏美サロン", "石川美容外科"],       # 石川千夏の下位
  ["優子エステ", "松本クリニック"],     # 松本優子の下位
  ["美奈サロン", "井上医院"],           # 井上美奈の下位
  ["理恵美容室", "木村皮膚科"],         # 木村理恵の下位
  ["由美サロン", "斎藤クリニック"],     # 斎藤由美の下位
  ["恵子エステ", "橋本医院"],           # 橋本恵子の下位
  ["智子サロン", "山口美容外科"],       # 山口智子の下位
  ["美和エステ", "吉田クリニック"]      # 吉田美和の下位
]
advisors.each_with_index do |parent, i|
  [
    { type: "サロン", name: salon_clinic_names[i][0], email_prefix: "salon" },
    { type: "クリニック", name: salon_clinic_names[i][1], email_prefix: "clinic" }
  ].each do |type_data|
    User.create!(
      id: user_id_seq,
      name: type_data[:name],
      email: "#{type_data[:email_prefix]}#{i + 1}@example.com",
      password: "111111",
      level_id: levels[type_data[:type]].id,
      referred_by_id: parent.id,
      lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
      confirmed_at: Time.current
    )
    user_id_seq += 1
    lstep_id_seq += 1
  end
end

# --- 追加パターン (1) ---
additional_advisor_names_1 = ["青木美香", "西田真理"]
additional_salon_names_1 = ["美香サロン", "真理エステ"]

2.times do |i|
  advisor = User.create!(
    id: user_id_seq,
    name: additional_advisor_names_1[i],
    email: "tokuyaku1_advisor#{i + 1}@example.com",
    password: "111111",
    level_id: levels["アドバイザー"].id,
    referred_by_id: special_agents[0].id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1

  User.create!(
    id: user_id_seq,
    name: additional_salon_names_1[i],
    email: "special1_salon#{i + 1}@example.com",
    password: "111111",
    level_id: levels["サロン"].id,
    referred_by_id: advisor.id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1
end

# --- 追加パターン (2) ---
additional_salon_names_2 = ["花音サロン", "美容室彩花"]

2.times do |i|
  User.create!(
    id: user_id_seq,
    name: additional_salon_names_2[i],
    email: "special2_salon#{i + 1}@example.com",
    password: "111111",
    level_id: levels["サロン"].id,
    referred_by_id: special_agents[1].id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1
end

# --- 追加パターン (3) ---
additional_advisor_names_3 = [
  ["長谷川優花", "田村美咲"],  # 第1グループ
  ["村田彩乃", "原田美優"]     # 第2グループ
]
additional_salon_names_3 = ["優花サロン", "彩乃エステ"]

2.times do |i|
  advisor1 = User.create!(
    id: user_id_seq,
    name: additional_advisor_names_3[i][0],
    email: "special3_advisor#{i + 1}_1@example.com",
    password: "111111",
    level_id: levels["アドバイザー"].id,
    referred_by_id: special_agents[2].id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1

  advisor2 = User.create!(
    id: user_id_seq,
    name: additional_advisor_names_3[i][1],
    email: "special3_advisor#{i + 1}_2@example.com",
    password: "111111",
    level_id: levels["アドバイザー"].id,
    referred_by_id: advisor1.id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1

  User.create!(
    id: user_id_seq,
    name: additional_salon_names_3[i],
    email: "special3_salon#{i + 1}@example.com",
    password: "111111",
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
product = product1
if product.nil?
  puts "⚠️  No products found. Skipping purchase data creation."
else
  # 田中美咲が自分で購入するデータを作成
  special_agent_1 = User.find_by(name: "田中美咲")
  
  if special_agent_1
    # 複数月の購入データを作成
    months = [
      { month: "2025-08", day: 8, quantity: 40 },
      { month: "2025-09", day: 15, quantity: 35 },
      { month: "2025-10", day: 5, quantity: 50 }
    ]
    
    months.each do |month_data|
      purchase = Purchase.create!(
        user_id: special_agent_1.id,        # 購入者
        purchased_at: "#{month_data[:month]}-#{format('%02d', month_data[:day])} 10:00:00"
      )
      
      PurchaseItem.create!(
        purchase: purchase,
        product: product,
        quantity: month_data[:quantity],
        unit_price: 50000,
        seller_price: 36000  # 総代理店の購入価格
      )
    end
    
    puts "✅ Created purchase data for 田中美咲 (8月, 9月, 10月)"
    
    # 他の代理店の購入データも複数月で作成
    agents.first(3).each_with_index do |agent, i|
      months.each_with_index do |month_data, month_idx|
        # 10月は1-17日の範囲に収める
        day = if month_data[:month] == "2025-10"
                6 + i + month_idx  # 6日から開始して重複を避ける
              else
                10 + i + month_idx
              end
        purchase = Purchase.create!(
          user_id: agent.id,        # 購入者
          purchased_at: "#{month_data[:month]}-#{format('%02d', day)} 14:00:00"
        )
        
        PurchaseItem.create!(
          purchase: purchase,
          product: product,
          quantity: 20 + (i * 5) + (month_idx * 3),  # 月ごとに少し数量を変える
          unit_price: 50000,
          seller_price: 38000  # 代理店の購入価格
        )
      end
    end
    
    puts "✅ Created purchase data for agents (8月, 9月, 10月)"
    
    # 中村結衣さんの自己購入データを作成（10月に7回のみ）
    nakamura = User.find_by(name: "中村結衣")
    if nakamura
      # 10月に7回購入（1日〜17日の範囲）
      purchase_days = [1, 3, 5, 7, 9, 11, 13]  # 10月1, 3, 5, 7, 9, 11, 13日
      purchase_days.each do |day|
        purchase = Purchase.create!(
          user_id: nakamura.id,
          purchased_at: "2025-10-#{format('%02d', day)} 16:00:00"
        )
        
        PurchaseItem.create!(
          purchase: purchase,
          product: product,
          quantity: 14,
          unit_price: 50000,
          seller_price: 40000
        )
      end
      puts "✅ Created purchase data for 中村結衣 (10月に7回)"
    end
    
    # 他のアドバイザーの購入データ（中村結衣以外）
    other_advisors = advisors.reject { |advisor| advisor.name == "中村結衣" }
    other_advisors.first(1).each_with_index do |advisor, i|
      months.each_with_index do |month_data, month_idx|
        # 10月は1-17日の範囲に収める
        day = if month_data[:month] == "2025-10"
                15 + i + month_idx  # 15, 16, 17日など
              else
                20 + i + month_idx
              end
        
        purchase = Purchase.create!(
          user_id: advisor.id,        # 購入者
          purchased_at: "#{month_data[:month]}-#{format('%02d', day)} 16:00:00"
        )
        
        PurchaseItem.create!(
          purchase: purchase,
          product: product,
          quantity: 10 + (i * 2) + (month_idx * 2),
          unit_price: 50000,
          seller_price: 40000  # アドバイザーの購入価格
        )
      end
    end
    
    puts "✅ Created purchase data for advisors (8月, 9月, 10月)"
  end
end

# お客様データの追加
puts "👥 Creating customer data..."

customer_names = [
  # 総代理店の直接お客様
  "山田太郎", "佐藤花子", "田中一郎", "鈴木美咲", "高橋健太", "伊藤由美",
  # 代理店の直接お客様  
  "渡辺直樹", "小林恵子", "加藤雅人", "森田真理", "清水智子", "石川大輔",
  "松本香織", "井上裕子", "木村正男", "斎藤美穂", "橋本和也", "山口千春",
  # アドバイザーの直接お客様
  "吉田博文", "中村愛子", "田村健一", "佐々木美和", "藤田直子", "岡田雄介",
  "村上香織", "長谷川太郎", "青木美香", "西田真理", "原田美優", "長谷川優花",
  "田村美咲", "村田彩乃", "川口智子", "大野裕子", "内田健太", "小川美穂",
  # サロン・クリニックのお客様
  "竹内雅人", "菊池恵子", "野口直樹", "坂本香織", "今井太郎", "宮本花子",
  "福田一郎", "岩田美咲", "上田健太", "杉山由美", "新井直樹", "池田恵子",
  "古川雅人", "平野真理", "横山智子", "安田大輔", "三浦香織", "中島裕子",
  "島田正男", "金子美穂"
]

customers = []
customer_index = 0

# 1. 総代理店の直接お客様（各総代理店に2名）
special_agents.each_with_index do |special_agent, i|
  2.times do |j|
    customer_name = customer_names[customer_index]
    customer = User.create!(
      id: user_id_seq,
      name: customer_name,
      email: "special_customer#{i + 1}-#{j + 1}@example.com",
      password: "111111",
      level_id: levels["お客様"].id,
      referred_by_id: special_agent.id,
      lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
      confirmed_at: Time.current
    )
    user_id_seq += 1
    lstep_id_seq += 1
    customers << customer
    customer_index += 1
  end
end

# 2. 代理店の直接お客様（各代理店に2名）
agents.each_with_index do |agent, i|
  2.times do |j|
    customer_name = customer_names[customer_index]
    customer = User.create!(
      id: user_id_seq,
      name: customer_name,
      email: "agent_customer#{i + 1}-#{j + 1}@example.com",
      password: "111111",
      level_id: levels["お客様"].id,
      referred_by_id: agent.id,
      lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
      confirmed_at: Time.current
    )
    user_id_seq += 1
    lstep_id_seq += 1
    customers << customer
    customer_index += 1
  end
end

# 3. アドバイザーの直接お客様（各アドバイザーに2名）
advisors.each_with_index do |advisor, i|
  2.times do |j|
    customer_name = customer_names[customer_index]
    customer = User.create!(
      id: user_id_seq,
      name: customer_name,
      email: "advisor_customer#{i + 1}-#{j + 1}@example.com",
      password: "111111",
      level_id: levels["お客様"].id,
      referred_by_id: advisor.id,
      lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
      confirmed_at: Time.current
    )
    user_id_seq += 1
    lstep_id_seq += 1
    customers << customer
    customer_index += 1
  end
end

# 4. サロン・クリニックの直接お客様（各サロン・クリニックに1名）
salons_and_clinics = User.joins(:level).where(levels: { value: [4, 5] })
salons_and_clinics.first(20).each_with_index do |salon_clinic, i|
  customer_name = customer_names[customer_index]
  customer = User.create!(
    id: user_id_seq,
    name: customer_name,
    email: "salon_customer#{i + 1}@example.com",
    password: "111111",
    level_id: levels["お客様"].id,
    referred_by_id: salon_clinic.id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1
  customers << customer
  customer_index += 1
end

puts "✅ Created #{customers.count} customers across all levels"

# お客様の購入データを作成
puts "🛒 Creating customer purchase data..."

if product
  # 各レベルのお客様から一部を選んで購入データを作成
  
  # 総代理店のお客様（6名中4名が購入）
  special_customers = customers.select { |c| c.email.include?('special_customer') }
  special_customers.first(4).each_with_index do |customer, i|
    months = [
      { month: "2025-08", day: 5 + i, quantity: 2 + (i % 2) },
      { month: "2025-09", day: 8 + i, quantity: 1 + (i % 3) },
      { month: "2025-10", day: 3 + i, quantity: 2 + ((i + 1) % 2) }
    ]
    
    months.each do |month_data|
      purchase = Purchase.create!(
        user_id: customer.id,
        purchased_at: "#{month_data[:month]}-#{format('%02d', month_data[:day])} 12:00:00"
      )
      
      PurchaseItem.create!(
        purchase: purchase,
        product: product,
        quantity: month_data[:quantity],
        unit_price: 50000,
        seller_price: 50000
      )
    end
  end
  
  # 代理店のお客様（12名中6名が購入）
  agent_customers = customers.select { |c| c.email.include?('agent_customer') }
  agent_customers.first(6).each_with_index do |customer, i|
    months = [
      { month: "2025-08", day: 10 + i, quantity: 1 + (i % 2) },
      { month: "2025-09", day: 12 + i, quantity: 1 + ((i + 1) % 3) },
      { month: "2025-10", day: 8 + i, quantity: 1 + (i % 2) }
    ]
    
    months.each do |month_data|
      purchase = Purchase.create!(
        user_id: customer.id,
        purchased_at: "#{month_data[:month]}-#{format('%02d', month_data[:day])} 14:00:00"
      )
      
      PurchaseItem.create!(
        purchase: purchase,
        product: product,
        quantity: month_data[:quantity],
        unit_price: 50000,
        seller_price: 50000
      )
    end
  end
  
  # 中村結衣さんの直下位お客様のみ購入（吉田博文、中村愛子）
  nakamura_customers = customers.select { |c| 
    c.email.include?('advisor_customer1-1') || c.email.include?('advisor_customer1-2')
  }
  
  nakamura_customers.each_with_index do |customer, i|
    # 10月に3回購入
    purchase_days = [5, 6, 12]  # 10月5, 6, 12日
    purchase_days.each do |day|
      purchase = Purchase.create!(
        user_id: customer.id,
        purchased_at: "2025-10-#{format('%02d', day)} 16:00:00"
      )
      
      PurchaseItem.create!(
        purchase: purchase,
        product: product,
        quantity: 1,
        unit_price: 50000,
        seller_price: 50000
      )
    end
  end
  
  # 中村結衣さんの間接的なお客様（サロン・クリニック経由）
  # 福田一郎（salon_customer1）と岩田美咲（salon_customer2）のみ購入
  indirect_customers = customers.select { |c| 
    c.email.include?('salon_customer1@') || c.email.include?('salon_customer2@')
  }
  
  indirect_customers.each_with_index do |customer, i|
    # 10月に1回購入
    day = 10 + i  # 10月10, 11日
    quantity = i == 0 ? 1 : 2  # 福田一郎は1個、岩田美咲は2個
    
    purchase = Purchase.create!(
      user_id: customer.id,
      purchased_at: "2025-10-#{format('%02d', day)} 18:00:00"
    )
    
    PurchaseItem.create!(
      purchase: purchase,
      product: product,
      quantity: quantity,
      unit_price: 50000,
      seller_price: 50000
    )
  end
  
  puts "✅ Created purchase data for customers across all levels (8月, 9月, 10月)"
  puts "   - Special agent customers: 4 customers purchasing"
  puts "   - Agent customers: 6 customers purchasing"  
  puts "   - Advisor customers: 8 customers purchasing"
  puts "   - Salon/Clinic customers: 6 customers purchasing"
end

puts "✅ Seeding completed!"