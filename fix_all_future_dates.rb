#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== 未来の購入データを過去の日付に修正 ==="

# 今日の日付
today = Date.current
puts "今日の日付: #{today}"

# 未来の購入データを取得
future_purchases = Purchase.where('purchased_at > ?', today.end_of_day)
                          .order(:purchased_at)

puts "修正対象の購入件数: #{future_purchases.count}"

if future_purchases.any?
  future_purchases.each_with_index do |purchase, index|
    old_date = purchase.purchased_at
    
    # 10月1日〜17日の範囲にランダムに分散
    new_day = 1 + (index % 17)  # 1〜17日に分散
    new_date = Date.new(2025, 10, new_day).beginning_of_day + old_date.hour.hours + old_date.min.minutes
    
    puts "購入ID #{purchase.id}: #{old_date.strftime('%m/%d %H:%M')} -> #{new_date.strftime('%m/%d %H:%M')}"
    
    purchase.update!(purchased_at: new_date)
  end
  
  puts "\n✅ #{future_purchases.count}件の購入データを過去の日付に修正しました"
else
  puts "未来の購入データはありません"
end

# 修正後の確認
puts "\n=== 修正後の確認 ==="
remaining_future = Purchase.where('purchased_at > ?', today.end_of_day).count
puts "残っている未来の購入データ: #{remaining_future}件"

# 10月の購入データ分布を再確認
october_purchases = Purchase.where(purchased_at: Date.new(2025, 10, 1)..Date.new(2025, 10, 31))
                           .group("DATE(purchased_at)")
                           .count
                           
puts "\n=== 修正後の10月購入データ分布 ==="
october_purchases.each do |date, count|
  date_obj = Date.parse(date)
  status = date_obj > today ? "未来" : "過去"
  puts "#{date}: #{count}件 (#{status})"
end