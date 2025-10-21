#!/usr/bin/env ruby
require_relative 'config/environment'

puts "🛒 Creating purchase data only..."

# 商品を取得
product1 = Product.find_by(name: "骨髄幹細胞培培養上清液")
if product1.nil?
  puts "⚠️  Product not found. Please run seeds first to create products."
  exit 1
end

# 中村結衣さんの自己購入データを作成（10月に3回のみ）
nakamura = User.find_by(name: "中村結衣")
if nakamura
  # 10月に3回購入（1日〜17日の範囲）
  purchase_days = [1, 5, 9]  # 10月1, 5, 9日
  purchase_days.each do |day|
    purchase = Purchase.create!(
      user_id: nakamura.id,
      purchased_at: "2025-10-#{format('%02d', day)} 16:00:00"
    )
    
    PurchaseItem.create!(
      purchase: purchase,
      product: product1,
      quantity: 14,
      unit_price: 50000,
      seller_price: 40000
    )
  end
  puts "✅ Created purchase data for 中村結衣 (10月に3回)"
end

# 中村結衣さんの直下位お客様のみ購入（吉田博文、中村愛子）
customers = User.joins(:level).where(levels: { name: "お客様" })
nakamura_customers = customers.select { |c| 
  c.email.include?('advisor_customer1-1') || c.email.include?('advisor_customer1-2')
}

nakamura_customers.each_with_index do |customer, i|
  # 10月に2回購入
  purchase_days = [6, 12]  # 10月6, 12日
  purchase_days.each do |day|
    purchase = Purchase.create!(
      user_id: customer.id,
      purchased_at: "2025-10-#{format('%02d', day)} 16:00:00"
    )
    
    PurchaseItem.create!(
      purchase: purchase,
      product: product1,
      quantity: 1,
      unit_price: 50000,
      seller_price: 50000
    )
  end
end
puts "✅ Created purchase data for 中村結衣's direct customers"

# 中村結衣さんの間接的なお客様（サロン・クリニック経由）
# 福田一郎（salon_customer1）のみ購入
indirect_customers = customers.select { |c| 
  c.email.include?('salon_customer1@')
}

indirect_customers.each_with_index do |customer, i|
  # 10月に1回購入
  day = 10  # 10月10日
  
  purchase = Purchase.create!(
    user_id: customer.id,
    purchased_at: "2025-10-#{format('%02d', day)} 18:00:00"
  )
  
  PurchaseItem.create!(
    purchase: purchase,
    product: product1,
    quantity: 1,
    unit_price: 50000,
    seller_price: 50000
  )
end
puts "✅ Created purchase data for 中村結衣's indirect customers"

# 鈴木愛美さんの自己購入データを追加
suzuki = User.find_by(name: "鈴木愛美")
if suzuki
  # 10月に2回購入
  purchase_days = [3, 8]  # 10月3, 8日
  purchase_days.each do |day|
    purchase = Purchase.create!(
      user_id: suzuki.id,
      purchased_at: "2025-10-#{format('%02d', day)} 14:00:00"
    )
    
    PurchaseItem.create!(
      purchase: purchase,
      product: product1,
      quantity: 6,
      unit_price: 50000,
      seller_price: 38000
    )
  end
  puts "✅ Created purchase data for 鈴木愛美 (10月に2回)"
end

# 鈴木愛美さんの直下位お客様の購入データを追加
suzuki_customers = customers.select { |c| 
  c.email.include?('agent_customer1-1') || c.email.include?('agent_customer1-2')
}

suzuki_customers.each_with_index do |customer, i|
  # 10月に1回購入
  day = 8 + i  # 10月8, 9日
  quantity = i == 0 ? 1 : 2  # 渡辺直樹は1個、小林恵子は2個
  
  purchase = Purchase.create!(
    user_id: customer.id,
    purchased_at: "2025-10-#{format('%02d', day)} 14:00:00"
  )
  
  PurchaseItem.create!(
    purchase: purchase,
    product: product1,
    quantity: quantity,
    unit_price: 50000,
    seller_price: 50000
  )
end
puts "✅ Created purchase data for 鈴木愛美's direct customers"

# 林美里さんの自己購入データを追加
hayashi = User.find_by(name: "林美里")
if hayashi
  # 10月に1回購入
  purchase = Purchase.create!(
    user_id: hayashi.id,
    purchased_at: "2025-10-15 16:00:00"
  )
  
  PurchaseItem.create!(
    purchase: purchase,
    product: product1,
    quantity: 8,
    unit_price: 50000,
    seller_price: 40000
  )
  puts "✅ Created purchase data for 林美里 (10月に1回)"
end

puts "✅ Purchase data creation completed!"

# 作成されたデータの確認
total_purchases = Purchase.count
total_items = PurchaseItem.count
puts "\n📊 Created data summary:"
puts "Total purchases: #{total_purchases}"
puts "Total purchase items: #{total_items}"

# 未来の日付チェック
today = Date.current
future_count = Purchase.where('purchased_at > ?', today.end_of_day).count
puts "Future purchases: #{future_count} (should be 0)"