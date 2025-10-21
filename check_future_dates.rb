#!/usr/bin/env ruby
require_relative 'config/environment'

# 今日の日付
today = Date.current
puts "今日の日付: #{today}"

# 未来の購入データを検索
future_purchases = Purchase.where('purchased_at > ?', today.end_of_day)
                          .includes(:user, :purchase_items => :product)
                          .order(:purchased_at)

puts "未来の購入データ件数: #{future_purchases.count}"

if future_purchases.any?
  puts "\n=== 未来の購入データ ==="
  
  future_purchases.each do |purchase|
    puts "購入ID: #{purchase.id}"
    puts "購入者: #{purchase.user.display_name}"
    puts "購入日: #{purchase.purchased_at}"
    purchase.purchase_items.each do |item|
      puts "  商品: #{item.product.name}, 数量: #{item.quantity}"
    end
    puts
  end
else
  puts "✅ 未来の購入データはありません"
end

# 10月の購入データ分布を確認
october_purchases = Purchase.where(purchased_at: Date.new(2025, 10, 1)..Date.new(2025, 10, 31))
                           .group("DATE(purchased_at)")
                           .count
                           
puts "\n=== 10月の購入データ分布 ==="
october_purchases.each do |date, count|
  date_obj = Date.parse(date)
  status = date_obj > today ? "未来" : "過去"
  puts "#{date}: #{count}件 (#{status})"
end