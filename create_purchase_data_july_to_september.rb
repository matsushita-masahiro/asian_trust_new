#!/usr/bin/env ruby
require_relative 'config/environment'

puts "🛒 Creating purchase data for July-September 2025..."

# 商品を取得
product1 = Product.find_by(name: "骨髄幹細胞培培養上清液")
if product1.nil?
  puts "⚠️  Product not found. Please run seeds first to create products."
  exit 1
end

# ユーザーを取得
nakamura = User.find_by(name: "中村結衣")
suzuki = User.find_by(name: "鈴木愛美")
hayashi = User.find_by(name: "林美里")
tanaka = User.find_by(name: "田中美咲")

customers = User.joins(:level).where(levels: { name: "お客様" })

# 9月分のデータ作成
puts "\n📅 Creating September 2025 data..."

# 中村結衣の自己購入（9月）
if nakamura
  purchase_days = [5, 15, 25]  # 9月5, 15, 25日
  purchase_days.each do |day|
    purchase = Purchase.create!(
      user_id: nakamura.id,
      purchased_at: "2025-09-#{format('%02d', day)} 15:00:00"
    )
    
    PurchaseItem.create!(
      purchase: purchase,
      product: product1,
      quantity: 10,
      unit_price: 50000,
      seller_price: 40000
    )
  end
  puts "✅ Created September purchase data for 中村結衣 (3回)"
end

# 鈴木愛美の自己購入（9月）
if suzuki
  purchase_days = [8, 18]  # 9月8, 18日
  purchase_days.each do |day|
    purchase = Purchase.create!(
      user_id: suzuki.id,
      purchased_at: "2025-09-#{format('%02d', day)} 14:00:00"
    )
    
    PurchaseItem.create!(
      purchase: purchase,
      product: product1,
      quantity: 5,
      unit_price: 50000,
      seller_price: 38000
    )
  end
  puts "✅ Created September purchase data for 鈴木愛美 (2回)"
end

# 林美里の自己購入（9月）
if hayashi
  purchase = Purchase.create!(
    user_id: hayashi.id,
    purchased_at: "2025-09-12 16:00:00"
  )
  
  PurchaseItem.create!(
    purchase: purchase,
    product: product1,
    quantity: 6,
    unit_price: 50000,
    seller_price: 40000
  )
  puts "✅ Created September purchase data for 林美里 (1回)"
end

# 顧客の購入（9月）
nakamura_customers = customers.select { |c| 
  c.email.include?('advisor_customer1-1') || c.email.include?('advisor_customer1-2')
}

nakamura_customers.each_with_index do |customer, i|
  day = 10 + i  # 9月10, 11日
  quantity = i == 0 ? 2 : 1  # 吉田博文は2個、中村愛子は1個
  
  purchase = Purchase.create!(
    user_id: customer.id,
    purchased_at: "2025-09-#{format('%02d', day)} 16:00:00"
  )
  
  PurchaseItem.create!(
    purchase: purchase,
    product: product1,
    quantity: quantity,
    unit_price: 50000,
    seller_price: 50000
  )
end

suzuki_customers = customers.select { |c| 
  c.email.include?('agent_customer1-1') || c.email.include?('agent_customer1-2')
}

suzuki_customers.each_with_index do |customer, i|
  day = 20 + i  # 9月20, 21日
  quantity = i == 0 ? 1 : 3  # 渡辺直樹は1個、小林恵子は3個
  
  purchase = Purchase.create!(
    user_id: customer.id,
    purchased_at: "2025-09-#{format('%02d', day)} 14:00:00"
  )
  
  PurchaseItem.create!(
    purchase: purchase,
    product: product1,
    quantity: quantity,
    unit_price: 50000,
    seller_price: 50000
  )
end
puts "✅ Created September purchase data for customers"

# 8月分のデータ作成
puts "\n📅 Creating August 2025 data..."

# 中村結衣の自己購入（8月）
if nakamura
  purchase_days = [3, 13, 23]  # 8月3, 13, 23日
  purchase_days.each do |day|
    purchase = Purchase.create!(
      user_id: nakamura.id,
      purchased_at: "2025-08-#{format('%02d', day)} 15:00:00"
    )
    
    PurchaseItem.create!(
      purchase: purchase,
      product: product1,
      quantity: 12,
      unit_price: 50000,
      seller_price: 40000
    )
  end
  puts "✅ Created August purchase data for 中村結衣 (3回)"
end

# 鈴木愛美の自己購入（8月）
if suzuki
  purchase_days = [6, 16, 26]  # 8月6, 16, 26日
  purchase_days.each do |day|
    purchase = Purchase.create!(
      user_id: suzuki.id,
      purchased_at: "2025-08-#{format('%02d', day)} 14:00:00"
    )
    
    PurchaseItem.create!(
      purchase: purchase,
      product: product1,
      quantity: 4,
      unit_price: 50000,
      seller_price: 38000
    )
  end
  puts "✅ Created August purchase data for 鈴木愛美 (3回)"
end

# 林美里の自己購入（8月）
if hayashi
  purchase_days = [10, 20]  # 8月10, 20日
  purchase_days.each do |day|
    purchase = Purchase.create!(
      user_id: hayashi.id,
      purchased_at: "2025-08-#{format('%02d', day)} 16:00:00"
    )
    
    PurchaseItem.create!(
      purchase: purchase,
      product: product1,
      quantity: 7,
      unit_price: 50000,
      seller_price: 40000
    )
  end
  puts "✅ Created August purchase data for 林美里 (2回)"
end

# 顧客の購入（8月）
nakamura_customers.each_with_index do |customer, i|
  day = 8 + i  # 8月8, 9日
  quantity = i == 0 ? 1 : 2  # 吉田博文は1個、中村愛子は2個
  
  purchase = Purchase.create!(
    user_id: customer.id,
    purchased_at: "2025-08-#{format('%02d', day)} 16:00:00"
  )
  
  PurchaseItem.create!(
    purchase: purchase,
    product: product1,
    quantity: quantity,
    unit_price: 50000,
    seller_price: 50000
  )
end

suzuki_customers.each_with_index do |customer, i|
  day = 18 + i  # 8月18, 19日
  quantity = i == 0 ? 2 : 1  # 渡辺直樹は2個、小林恵子は1個
  
  purchase = Purchase.create!(
    user_id: customer.id,
    purchased_at: "2025-08-#{format('%02d', day)} 14:00:00"
  )
  
  PurchaseItem.create!(
    purchase: purchase,
    product: product1,
    quantity: quantity,
    unit_price: 50000,
    seller_price: 50000
  )
end
puts "✅ Created August purchase data for customers"

# 7月分のデータ作成
puts "\n📅 Creating July 2025 data..."

# 中村結衣の自己購入（7月）
if nakamura
  purchase_days = [2, 12, 22]  # 7月2, 12, 22日
  purchase_days.each do |day|
    purchase = Purchase.create!(
      user_id: nakamura.id,
      purchased_at: "2025-07-#{format('%02d', day)} 15:00:00"
    )
    
    PurchaseItem.create!(
      purchase: purchase,
      product: product1,
      quantity: 8,
      unit_price: 50000,
      seller_price: 40000
    )
  end
  puts "✅ Created July purchase data for 中村結衣 (3回)"
end

# 鈴木愛美の自己購入（7月）
if suzuki
  purchase_days = [5, 15]  # 7月5, 15日
  purchase_days.each do |day|
    purchase = Purchase.create!(
      user_id: suzuki.id,
      purchased_at: "2025-07-#{format('%02d', day)} 14:00:00"
    )
    
    PurchaseItem.create!(
      purchase: purchase,
      product: product1,
      quantity: 7,
      unit_price: 50000,
      seller_price: 38000
    )
  end
  puts "✅ Created July purchase data for 鈴木愛美 (2回)"
end

# 林美里の自己購入（7月）
if hayashi
  purchase_days = [8, 18, 28]  # 7月8, 18, 28日
  purchase_days.each do |day|
    purchase = Purchase.create!(
      user_id: hayashi.id,
      purchased_at: "2025-07-#{format('%02d', day)} 16:00:00"
    )
    
    PurchaseItem.create!(
      purchase: purchase,
      product: product1,
      quantity: 5,
      unit_price: 50000,
      seller_price: 40000
    )
  end
  puts "✅ Created July purchase data for 林美里 (3回)"
end

# 顧客の購入（7月）
nakamura_customers.each_with_index do |customer, i|
  day = 6 + i  # 7月6, 7日
  quantity = i == 0 ? 3 : 1  # 吉田博文は3個、中村愛子は1個
  
  purchase = Purchase.create!(
    user_id: customer.id,
    purchased_at: "2025-07-#{format('%02d', day)} 16:00:00"
  )
  
  PurchaseItem.create!(
    purchase: purchase,
    product: product1,
    quantity: quantity,
    unit_price: 50000,
    seller_price: 50000
  )
end

suzuki_customers.each_with_index do |customer, i|
  day = 16 + i  # 7月16, 17日
  quantity = i == 0 ? 1 : 2  # 渡辺直樹は1個、小林恵子は2個
  
  purchase = Purchase.create!(
    user_id: customer.id,
    purchased_at: "2025-07-#{format('%02d', day)} 14:00:00"
  )
  
  PurchaseItem.create!(
    purchase: purchase,
    product: product1,
    quantity: quantity,
    unit_price: 50000,
    seller_price: 50000
  )
end
puts "✅ Created July purchase data for customers"

puts "\n✅ Purchase data creation completed for July-September 2025!"

# 作成されたデータの確認
july_purchases = Purchase.where(purchased_at: Date.new(2025, 7, 1)..Date.new(2025, 7, 31)).count
august_purchases = Purchase.where(purchased_at: Date.new(2025, 8, 1)..Date.new(2025, 8, 31)).count
september_purchases = Purchase.where(purchased_at: Date.new(2025, 9, 1)..Date.new(2025, 9, 30)).count

puts "\n📊 Created data summary:"
puts "July 2025 purchases: #{july_purchases}"
puts "August 2025 purchases: #{august_purchases}"
puts "September 2025 purchases: #{september_purchases}"
puts "Total new purchases: #{july_purchases + august_purchases + september_purchases}"