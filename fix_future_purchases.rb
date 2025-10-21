#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== 未来の購入データを修正 ==="

# 今日の日付
today = Date.current
puts "今日の日付: #{today}"

# 未来の購入データを検索
future_purchases = Purchase.where('purchased_at > ?', today.end_of_day)
                          .includes(:user, :purchase_items => :product)
                          .order(:purchased_at)

puts "未来の購入データ件数: #{future_purchases.count}"

if future_purchases.any?
  puts "\n=== 修正対象の購入データ ==="
  
  future_purchases.each do |purchase|
    puts "購入ID: #{purchase.id}"
    puts "購入者: #{purchase.user.display_name}"
    puts "現在の購入日: #{purchase.purchased_at}"
    
    # 購入日を過去の日付に修正
    # 10月の購入は10月1日〜17日の範囲に収める
    if purchase.purchased_at.month == 10
      # 10月18日以降の購入を10月1日〜17日に分散
      new_day = rand(1..17)
      new_date = Date.new(2025, 10, new_day).beginning_of_day + purchase.purchased_at.hour.hours + purchase.purchased_at.min.minutes
    else
      # その他の月は月初に移動
      new_date = purchase.purchased_at.beginning_of_month + purchase.purchased_at.hour.hours + purchase.purchased_at.min.minutes
    end
    
    puts "新しい購入日: #{new_date}"
    
    # 購入日を更新
    purchase.update!(purchased_at: new_date)
    
    puts "✅ 修正完了"
    puts
  end
  
  puts "=== 修正完了 ==="
  puts "#{future_purchases.count}件の購入データを過去の日付に修正しました"
else
  puts "未来の購入データはありません"
end

# 修正後の確認
puts "\n=== 修正後の確認 ==="
remaining_future = Purchase.where('purchased_at > ?', today.end_of_day).count
puts "残っている未来の購入データ: #{remaining_future}件"

# 10月の購入データ分布を確認
october_purchases = Purchase.where(purchased_at: Date.new(2025, 10, 1)..Date.new(2025, 10, 31))
                           .group("DATE(purchased_at)")
                           .count
                           
puts "\n=== 10月の購入データ分布 ==="
october_purchases.each do |date, count|
  puts "#{date}: #{count}件"
end