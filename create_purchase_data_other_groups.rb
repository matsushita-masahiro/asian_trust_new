#!/usr/bin/env ruby
require_relative 'config/environment'

puts "🛒 Creating purchase data for other special agent groups..."

# 商品を取得
product1 = Product.find_by(name: "骨髄幹細胞培培養上清液")
if product1.nil?
  puts "⚠️  Product not found. Please run seeds first to create products."
  exit 1
end

# 佐藤花音グループのユーザーを取得
sato_group = User.find_by(name: "佐藤花音")
ito_mayu = User.find_by(name: "伊藤真由")
watanabe_mai = User.find_by(name: "渡辺麻衣")
ishikawa_chinatsu = User.find_by(name: "石川千夏")
matsumoto_yuko = User.find_by(name: "松本優子")
inoue_mina = User.find_by(name: "井上美奈")
kimura_rie = User.find_by(name: "木村理恵")

# 山田優香グループのユーザーを取得
yamada_group = User.find_by(name: "山田優香")
kobayashi_saori = User.find_by(name: "小林沙織")
kato_miho = User.find_by(name: "加藤美穂")
saito_yumi = User.find_by(name: "斎藤由美")
hashimoto_keiko = User.find_by(name: "橋本恵子")
yamaguchi_tomoko = User.find_by(name: "山口智子")
yoshida_miwa = User.find_by(name: "吉田美和")

# 各月のデータを作成する関数
def create_monthly_data(users_data, month, product)
  puts "\n📅 Creating #{Date::MONTHNAMES[month]} 2025 data..."
  
  users_data.each do |user_info|
    user = user_info[:user]
    next unless user
    
    purchase_count = user_info[:purchase_count]
    quantity_per_purchase = user_info[:quantity]
    seller_price = user_info[:seller_price]
    
    purchase_count.times do |i|
      day = (i + 1) * 7 + rand(5)  # 7日間隔 + ランダム
      day = [day, 28].min  # 月末を超えないように
      
      purchase = Purchase.create!(
        user_id: user.id,
        purchased_at: "2025-#{format('%02d', month)}-#{format('%02d', day)} #{10 + rand(8)}:00:00"
      )
      
      PurchaseItem.create!(
        purchase: purchase,
        product: product,
        quantity: quantity_per_purchase,
        unit_price: 50000,
        seller_price: seller_price
      )
    end
    
    puts "✅ Created #{purchase_count} purchases for #{user.name}"
  end
end

# 10月のデータ作成
sato_group_october = [
  { user: ito_mayu, purchase_count: 2, quantity: 8, seller_price: 38000 },
  { user: watanabe_mai, purchase_count: 1, quantity: 12, seller_price: 38000 },
  { user: ishikawa_chinatsu, purchase_count: 3, quantity: 6, seller_price: 40000 },
  { user: matsumoto_yuko, purchase_count: 2, quantity: 4, seller_price: 40000 },
  { user: inoue_mina, purchase_count: 1, quantity: 10, seller_price: 40000 },
  { user: kimura_rie, purchase_count: 2, quantity: 5, seller_price: 40000 }
]

yamada_group_october = [
  { user: kobayashi_saori, purchase_count: 2, quantity: 7, seller_price: 38000 },
  { user: kato_miho, purchase_count: 3, quantity: 5, seller_price: 38000 },
  { user: saito_yumi, purchase_count: 1, quantity: 9, seller_price: 40000 },
  { user: hashimoto_keiko, purchase_count: 2, quantity: 6, seller_price: 40000 },
  { user: yamaguchi_tomoko, purchase_count: 2, quantity: 8, seller_price: 40000 },
  { user: yoshida_miwa, purchase_count: 1, quantity: 11, seller_price: 40000 }
]

create_monthly_data(sato_group_october, 10, product1)
create_monthly_data(yamada_group_october, 10, product1)

# 9月のデータ作成
sato_group_september = [
  { user: ito_mayu, purchase_count: 3, quantity: 6, seller_price: 38000 },
  { user: watanabe_mai, purchase_count: 2, quantity: 8, seller_price: 38000 },
  { user: ishikawa_chinatsu, purchase_count: 2, quantity: 7, seller_price: 40000 },
  { user: matsumoto_yuko, purchase_count: 1, quantity: 12, seller_price: 40000 },
  { user: inoue_mina, purchase_count: 2, quantity: 5, seller_price: 40000 },
  { user: kimura_rie, purchase_count: 3, quantity: 4, seller_price: 40000 }
]

yamada_group_september = [
  { user: kobayashi_saori, purchase_count: 1, quantity: 10, seller_price: 38000 },
  { user: kato_miho, purchase_count: 2, quantity: 6, seller_price: 38000 },
  { user: saito_yumi, purchase_count: 3, quantity: 5, seller_price: 40000 },
  { user: hashimoto_keiko, purchase_count: 1, quantity: 8, seller_price: 40000 },
  { user: yamaguchi_tomoko, purchase_count: 2, quantity: 7, seller_price: 40000 },
  { user: yoshida_miwa, purchase_count: 2, quantity: 6, seller_price: 40000 }
]

create_monthly_data(sato_group_september, 9, product1)
create_monthly_data(yamada_group_september, 9, product1)

# 8月のデータ作成
sato_group_august = [
  { user: ito_mayu, purchase_count: 2, quantity: 9, seller_price: 38000 },
  { user: watanabe_mai, purchase_count: 3, quantity: 5, seller_price: 38000 },
  { user: ishikawa_chinatsu, purchase_count: 1, quantity: 11, seller_price: 40000 },
  { user: matsumoto_yuko, purchase_count: 2, quantity: 7, seller_price: 40000 },
  { user: inoue_mina, purchase_count: 3, quantity: 4, seller_price: 40000 },
  { user: kimura_rie, purchase_count: 1, quantity: 13, seller_price: 40000 }
]

yamada_group_august = [
  { user: kobayashi_saori, purchase_count: 3, quantity: 6, seller_price: 38000 },
  { user: kato_miho, purchase_count: 1, quantity: 11, seller_price: 38000 },
  { user: saito_yumi, purchase_count: 2, quantity: 8, seller_price: 40000 },
  { user: hashimoto_keiko, purchase_count: 3, quantity: 5, seller_price: 40000 },
  { user: yamaguchi_tomoko, purchase_count: 1, quantity: 12, seller_price: 40000 },
  { user: yoshida_miwa, purchase_count: 2, quantity: 7, seller_price: 40000 }
]

create_monthly_data(sato_group_august, 8, product1)
create_monthly_data(yamada_group_august, 8, product1)

# 7月のデータ作成
sato_group_july = [
  { user: ito_mayu, purchase_count: 1, quantity: 8, seller_price: 38000 },
  { user: watanabe_mai, purchase_count: 2, quantity: 10, seller_price: 38000 },
  { user: ishikawa_chinatsu, purchase_count: 3, quantity: 5, seller_price: 40000 },
  { user: matsumoto_yuko, purchase_count: 1, quantity: 9, seller_price: 40000 },
  { user: inoue_mina, purchase_count: 2, quantity: 6, seller_price: 40000 },
  { user: kimura_rie, purchase_count: 2, quantity: 7, seller_price: 40000 }
]

yamada_group_july = [
  { user: kobayashi_saori, purchase_count: 2, quantity: 8, seller_price: 38000 },
  { user: kato_miho, purchase_count: 3, quantity: 6, seller_price: 38000 },
  { user: saito_yumi, purchase_count: 1, quantity: 10, seller_price: 40000 },
  { user: hashimoto_keiko, purchase_count: 2, quantity: 7, seller_price: 40000 },
  { user: yamaguchi_tomoko, purchase_count: 3, quantity: 5, seller_price: 40000 },
  { user: yoshida_miwa, purchase_count: 1, quantity: 12, seller_price: 40000 }
]

create_monthly_data(sato_group_july, 7, product1)
create_monthly_data(yamada_group_july, 7, product1)

# 顧客の購入データも追加
puts "\n👥 Creating customer purchase data..."

# 各グループの顧客を取得
sato_customers = User.joins(:level).where(levels: { name: "お客様" })
                    .joins("JOIN users referrers ON users.referred_by_id = referrers.id")
                    .joins("JOIN users agents ON referrers.referred_by_id = agents.id")
                    .joins("JOIN users tokuyaku ON agents.referred_by_id = tokuyaku.id")
                    .where("tokuyaku.name = ?", "佐藤花音")
                    .limit(8)

yamada_customers = User.joins(:level).where(levels: { name: "お客様" })
                      .joins("JOIN users referrers ON users.referred_by_id = referrers.id")
                      .joins("JOIN users agents ON referrers.referred_by_id = agents.id")
                      .joins("JOIN users tokuyaku ON agents.referred_by_id = tokuyaku.id")
                      .where("tokuyaku.name = ?", "山田優香")
                      .limit(8)

# 顧客の購入データを各月に作成
[7, 8, 9, 10].each do |month|
  sato_customers.each_with_index do |customer, i|
    next if rand(3) == 0  # 33%の確率でスキップ（全員が毎月購入するわけではない）
    
    day = 5 + i * 3 + rand(3)
    day = [day, 28].min
    
    purchase = Purchase.create!(
      user_id: customer.id,
      purchased_at: "2025-#{format('%02d', month)}-#{format('%02d', day)} #{12 + rand(6)}:00:00"
    )
    
    PurchaseItem.create!(
      purchase: purchase,
      product: product1,
      quantity: 1 + rand(3),  # 1-3個
      unit_price: 50000,
      seller_price: 50000
    )
  end
  
  yamada_customers.each_with_index do |customer, i|
    next if rand(3) == 0  # 33%の確率でスキップ
    
    day = 8 + i * 3 + rand(3)
    day = [day, 28].min
    
    purchase = Purchase.create!(
      user_id: customer.id,
      purchased_at: "2025-#{format('%02d', month)}-#{format('%02d', day)} #{12 + rand(6)}:00:00"
    )
    
    PurchaseItem.create!(
      purchase: purchase,
      product: product1,
      quantity: 1 + rand(3),  # 1-3個
      unit_price: 50000,
      seller_price: 50000
    )
  end
end

puts "✅ Created customer purchase data for both groups"

puts "\n✅ Purchase data creation completed for all special agent groups!"

# 作成されたデータの確認
july_total = Purchase.where(purchased_at: Date.new(2025, 7, 1)..Date.new(2025, 7, 31)).count
august_total = Purchase.where(purchased_at: Date.new(2025, 8, 1)..Date.new(2025, 8, 31)).count
september_total = Purchase.where(purchased_at: Date.new(2025, 9, 1)..Date.new(2025, 9, 30)).count
october_total = Purchase.where(purchased_at: Date.new(2025, 10, 1)..Date.new(2025, 10, 31)).count

puts "\n📊 Total purchase data summary:"
puts "July 2025: #{july_total} purchases"
puts "August 2025: #{august_total} purchases"
puts "September 2025: #{september_total} purchases"
puts "October 2025: #{october_total} purchases"
puts "Total: #{july_total + august_total + september_total + october_total} purchases"