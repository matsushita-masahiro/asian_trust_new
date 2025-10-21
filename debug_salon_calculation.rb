#!/usr/bin/env ruby
require_relative 'config/environment'

user = User.find_by(name: "中村結衣")
service = IncentiveCalculationService.from_month_string(user, "2025-10")

puts "=== 計算範囲 ==="
puts "開始日: #{service.start_date}"
puts "終了日: #{service.end_date}"
puts

# サロンのお客様の購入を個別に確認
salon_customer1 = User.find_by(name: "福田一郎")
salon_customer2 = User.find_by(name: "岩田美咲")

[salon_customer1, salon_customer2].each do |customer|
  puts "=== #{customer.display_name}の購入詳細 ==="
  
  # 全購入を確認
  all_purchases = Purchase.where(user_id: customer.id).includes(:purchase_items => :product)
  puts "全購入件数: #{all_purchases.count}"
  
  all_purchases.each do |purchase|
    in_range = (service.start_date..service.end_date).cover?(purchase.purchased_at)
    puts "購入日: #{purchase.purchased_at} (範囲内: #{in_range})"
    
    purchase.purchase_items.each do |item|
      puts "  商品: #{item.product.name}, 数量: #{item.quantity}"
    end
  end
  
  # 範囲内の購入のみ
  range_purchases = Purchase.where(
    user_id: customer.id,
    purchased_at: service.start_date..service.end_date
  ).includes(:purchase_items => :product)
  
  puts "範囲内購入件数: #{range_purchases.count}"
  
  # 子孫IDに含まれているか確認
  descendant_ids = user.descendant_ids
  puts "子孫IDに含まれている: #{descendant_ids.include?(customer.id)}"
  
  # 経路確認
  path = customer.path_to_ancestor(user)
  puts "経路: #{path ? path.map(&:display_name).join(' -> ') : 'なし'}"
  puts "経路の長さ: #{path ? path.length : 0}"
  
  puts
end

# 実際のクエリを確認
descendant_user_ids = user.descendant_ids.reject { |uid| uid == user.id }
puts "=== 実際のクエリ結果 ==="
puts "子孫ユーザーID: #{descendant_user_ids}"

descendant_purchase_items = PurchaseItem.joins(:purchase)
                                       .where(purchases: { user_id: descendant_user_ids, purchased_at: service.start_date..service.end_date })
                                       .includes(:product, purchase: :user)

puts "子孫の購入アイテム数: #{descendant_purchase_items.count}"

descendant_purchase_items.each do |item|
  purchase = item.purchase
  puts "購入者: #{purchase.user.display_name}, 商品: #{item.product.name}, 購入日: #{purchase.purchased_at}"
end