#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== 2025年10月の全購入データ ==="

start_date = Date.new(2025, 10, 1)
end_date = Date.new(2025, 10, 31)

purchases = Purchase.where(purchased_at: start_date..end_date)
                   .includes(:user, :purchase_items => :product)
                   .order(:purchased_at)

puts "総購入件数: #{purchases.count}"
puts

purchases.each do |purchase|
  puts "購入ID: #{purchase.id}"
  puts "購入者: #{purchase.user.display_name} (#{purchase.user.level&.name})"
  puts "購入日: #{purchase.purchased_at}"
  
  purchase.purchase_items.each do |item|
    puts "  商品: #{item.product.name}"
    puts "  数量: #{item.quantity}"
    puts "  単価: ¥#{item.unit_price}"
    puts "  小計: ¥#{item.unit_price * item.quantity}"
  end
  
  total = purchase.purchase_items.sum { |item| item.unit_price * item.quantity }
  puts "  購入合計: ¥#{total}"
  puts
end

# 中村結衣さんの子孫ユーザーを確認
user = User.find(11)
puts "=== #{user.display_name}さんの子孫ユーザー ==="
descendant_ids = user.descendant_ids
descendants = User.where(id: descendant_ids).includes(:level)

descendants.each do |descendant|
  puts "#{descendant.display_name} (#{descendant.level&.name}) - ID: #{descendant.id}"
  
  # この子孫の購入を確認
  descendant_purchases = purchases.where(user_id: descendant.id)
  if descendant_purchases.any?
    descendant_purchases.each do |purchase|
      total = purchase.purchase_items.sum { |item| item.unit_price * item.quantity }
      puts "  購入: ¥#{total} (#{purchase.purchased_at.strftime('%m/%d')})"
    end
  else
    puts "  購入なし"
  end
end