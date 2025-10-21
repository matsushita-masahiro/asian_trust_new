#!/usr/bin/env ruby
require_relative 'config/environment'

# 中村結衣さんの自己購入を確認
user = User.find_by(name: "中村結衣")
puts "=== #{user.display_name}さんの自己購入確認 ==="

# 10月の自己購入を確認
october_purchases = Purchase.where(
  user_id: user.id,
  purchased_at: Date.new(2025, 10, 1)..Date.new(2025, 10, 31)
).includes(:purchase_items => :product)

puts "10月の自己購入件数: #{october_purchases.count}"

october_purchases.each do |purchase|
  puts "\n購入日: #{purchase.purchased_at}"
  total = 0
  
  purchase.purchase_items.each do |item|
    subtotal = item.unit_price * item.quantity
    total += subtotal
    puts "  #{item.product.name} × #{item.quantity} = ¥#{subtotal}"
    
    # インセンティブ計算
    product = item.product
    base_price = product.base_price
    my_level = user.level_at(purchase.purchased_at)
    my_price = product.product_prices.find_by(level_id: my_level.id)&.price || 0
    
    incentive_unit = base_price - my_price
    item_incentive = incentive_unit * item.quantity
    
    puts "    基本価格: ¥#{base_price}, 自分の価格: ¥#{my_price}"
    puts "    インセンティブ: ¥#{incentive_unit} × #{item.quantity} = ¥#{item_incentive}"
  end
  
  puts "  購入合計: ¥#{total}"
end

# 全期間の自己購入も確認
all_purchases = Purchase.where(user_id: user.id).includes(:purchase_items => :product)
puts "\n=== 全期間の自己購入 ==="
puts "全購入件数: #{all_purchases.count}"

all_purchases.each do |purchase|
  total = purchase.purchase_items.sum { |item| item.unit_price * item.quantity }
  puts "#{purchase.purchased_at.strftime('%Y-%m-%d')}: ¥#{total}"
end

# インセンティブ計算サービスでの自己購入計算を確認
service = IncentiveCalculationService.from_month_string(user, "2025-10")
result = service.calculate_detailed_incentives

puts "\n=== インセンティブ計算サービス結果 ==="
puts "自己購入インセンティブ: ¥#{result[:details][:own_sales]}"
puts "階層差額インセンティブ: ¥#{result[:details][:descendant_sales]}"
puts "総インセンティブ: ¥#{result[:total]}"