#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== PurchaseItemの価格整合性チェック ==="

# 全てのPurchaseItemを確認
purchase_items = PurchaseItem.joins(:purchase)
                            .includes(:product, purchase: :user)
                            .order('purchases.purchased_at DESC')

discrepancies = []
total_items = purchase_items.count

puts "総PurchaseItem件数: #{total_items}"
puts

purchase_items.each_with_index do |item, index|
  purchase = item.purchase
  user = purchase.user
  product = item.product
  purchase_date = purchase.purchased_at
  
  # 購入時点でのユーザーのレベル
  user_level_at_purchase = user.level_at(purchase_date)
  
  # そのレベルでの製品価格
  expected_price = product.product_prices.find_by(level_id: user_level_at_purchase.id)&.price
  
  # 実際の購入価格（seller_price）
  actual_price = item.seller_price
  
  if expected_price != actual_price
    discrepancy = {
      purchase_id: purchase.id,
      item_id: item.id,
      user_name: user.display_name,
      user_level: user_level_at_purchase&.name,
      product_name: product.name,
      purchase_date: purchase_date,
      expected_price: expected_price,
      actual_price: actual_price,
      unit_price: item.unit_price,
      quantity: item.quantity
    }
    discrepancies << discrepancy
  end
  
  # 進捗表示（100件ごと）
  if (index + 1) % 100 == 0
    puts "チェック済み: #{index + 1}/#{total_items}"
  end
end

puts "\n=== 結果 ==="
puts "価格不整合件数: #{discrepancies.count}"

if discrepancies.any?
  puts "\n=== 価格不整合の詳細 ==="
  discrepancies.each_with_index do |disc, index|
    puts "#{index + 1}. 購入ID: #{disc[:purchase_id]}"
    puts "   購入者: #{disc[:user_name]} (#{disc[:user_level]})"
    puts "   商品: #{disc[:product_name]}"
    puts "   購入日: #{disc[:purchase_date]}"
    puts "   期待価格: ¥#{disc[:expected_price]}"
    puts "   実際価格: ¥#{disc[:actual_price]}"
    puts "   単価: ¥#{disc[:unit_price]}"
    puts "   数量: #{disc[:quantity]}"
    puts
  end
else
  puts "✅ 全てのPurchaseItemで価格が整合しています"
end

# 統計情報
puts "=== 統計情報 ==="
puts "総チェック件数: #{total_items}"
puts "整合性OK: #{total_items - discrepancies.count}"
puts "不整合: #{discrepancies.count}"

if discrepancies.any?
  # レベル別の不整合件数
  level_discrepancies = discrepancies.group_by { |d| d[:user_level] }
  puts "\n=== レベル別不整合件数 ==="
  level_discrepancies.each do |level, items|
    puts "#{level}: #{items.count}件"
  end
end