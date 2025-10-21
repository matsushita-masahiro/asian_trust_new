#!/usr/bin/env ruby
require_relative 'config/environment'

# 中村結衣さん（ID: 11）のインセンティブ計算をデバッグ
user = User.find(11)
puts "=== #{user.display_name}さんのインセンティブ計算デバッグ ==="
puts "現在のレベル: #{user.level&.name}"
puts "インセンティブ受領資格: #{user.bonus_eligible?}"
puts

# 2025年10月のインセンティブ計算
service = IncentiveCalculationService.from_month_string(user, "2025-10")
result = service.calculate_detailed_incentives

puts "=== 計算結果 ==="
puts "総インセンティブ: ¥#{result[:total]}"
puts "自己購入インセンティブ: ¥#{result[:details][:own_sales]}"
puts "階層差額インセンティブ: ¥#{result[:details][:descendant_sales]}"
puts "対象購入件数: #{result[:details][:purchase_count]}"
puts

# 階層別売上を確認
puts "=== 階層別売上 ==="
hierarchy_data = service.calculate_hierarchy_sales
hierarchy_data.each do |user_id, data|
  puts "#{data[:user_name]} (#{data[:level]}): 売上¥#{data[:sales_total]}, インセンティブ¥#{data[:incentive_amount]}"
end
puts

# 購入詳細を確認
puts "=== 購入詳細 ==="
result[:details][:purchase_details].each_with_index do |detail, index|
  puts "#{index + 1}. #{detail[:purchaser_name]} - #{detail[:product_name]}"
  puts "   購入日: #{detail[:purchase_date]}"
  puts "   数量: #{detail[:quantity]}, 単価: ¥#{detail[:unit_price]}"
  puts "   インセンティブ単価: ¥#{detail[:incentive_unit_price]}"
  puts "   合計インセンティブ: ¥#{detail[:total_incentive]}"
  puts "   計算式: #{detail[:calculation_details][:calculation_formula]}"
  puts
end

# 直下位ユーザーの詳細確認
puts "=== 直下位ユーザーの詳細 ==="
user.referrals.each do |referral|
  puts "#{referral.display_name} (#{referral.level&.name})"
  
  # このユーザーの購入を確認
  purchase_items = PurchaseItem.joins(:purchase)
                              .where(purchases: { user_id: referral.id, purchased_at: service.start_date..service.end_date })
                              .includes(:product, purchase: :user)
  
  purchase_items.each do |item|
    purchase_date = item.purchase.purchased_at
    my_level_at_purchase = user.level_at(purchase_date)
    referral_level_at_purchase = referral.level_at(purchase_date)
    
    product = item.product
    base_price = product.base_price
    my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
    referral_price = product.product_prices.find_by(level_id: referral_level_at_purchase.id)&.price || 0
    
    puts "  商品: #{product.name}"
    puts "  購入日: #{purchase_date}"
    puts "  基本価格: ¥#{base_price}"
    puts "  #{referral.display_name}の価格: ¥#{referral_price} (#{referral_level_at_purchase&.name})"
    puts "  #{user.display_name}の価格: ¥#{my_price} (#{my_level_at_purchase&.name})"
    puts "  階層差額: ¥#{referral_price - my_price} × #{item.quantity} = ¥#{(referral_price - my_price) * item.quantity}"
    puts
  end
end