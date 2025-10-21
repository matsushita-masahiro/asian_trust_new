#!/usr/bin/env ruby
require_relative 'config/environment'

user = User.find(11)
service = IncentiveCalculationService.from_month_string(user, "2025-10")

puts "=== 日付範囲確認 ==="
puts "開始日: #{service.start_date}"
puts "終了日: #{service.end_date}"
puts

# 福田一郎と岩田美咲の購入を直接確認
customer1 = User.find(101) # 福田一郎
customer2 = User.find(102) # 岩田美咲

puts "=== 福田一郎の全購入 ==="
customer1_all_purchases = Purchase.where(user_id: customer1.id).includes(:purchase_items => :product)
customer1_all_purchases.each do |purchase|
  puts "購入日: #{purchase.purchased_at}"
  puts "範囲内: #{(service.start_date..service.end_date).cover?(purchase.purchased_at)}"
  purchase.purchase_items.each do |item|
    puts "  商品: #{item.product.name}, 数量: #{item.quantity}, 単価: ¥#{item.unit_price}"
  end
  puts
end

puts "=== 岩田美咲の全購入 ==="
customer2_all_purchases = Purchase.where(user_id: customer2.id).includes(:purchase_items => :product)
customer2_all_purchases.each do |purchase|
  puts "購入日: #{purchase.purchased_at}"
  puts "範囲内: #{(service.start_date..service.end_date).cover?(purchase.purchased_at)}"
  purchase.purchase_items.each do |item|
    puts "  商品: #{item.product.name}, 数量: #{item.quantity}, 単価: ¥#{item.unit_price}"
  end
  puts
end

# 子孫IDに含まれているかも確認
descendant_ids = user.descendant_ids
puts "=== 子孫ID確認 ==="
puts "中村結衣の子孫ID: #{descendant_ids}"
puts "福田一郎 (ID: #{customer1.id}) が含まれている: #{descendant_ids.include?(customer1.id)}"
puts "岩田美咲 (ID: #{customer2.id}) が含まれている: #{descendant_ids.include?(customer2.id)}"