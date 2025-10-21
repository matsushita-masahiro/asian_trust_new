#!/usr/bin/env ruby
require_relative 'config/environment'

# 中村結衣さんの10月の購入日を範囲内に修正
user = User.find_by(name: "中村結衣")
puts "=== #{user.display_name}さんの購入日修正 ==="

# 10月の購入を取得
october_purchases = Purchase.where(
  user_id: user.id,
  purchased_at: Date.new(2025, 10, 1)..Date.new(2025, 10, 31)
)

puts "修正対象の購入件数: #{october_purchases.count}"

october_purchases.each_with_index do |purchase, index|
  old_date = purchase.purchased_at
  
  # 10月1日〜17日の範囲に分散
  new_day = 1 + (index % 17)  # 1〜17日に分散
  new_date = Date.new(2025, 10, new_day).beginning_of_day + old_date.hour.hours + old_date.min.minutes
  
  puts "購入ID #{purchase.id}: #{old_date} -> #{new_date}"
  
  purchase.update!(purchased_at: new_date)
end

puts "✅ 修正完了"

# 修正後の確認
puts "\n=== 修正後の確認 ==="
updated_purchases = Purchase.where(
  user_id: user.id,
  purchased_at: Date.new(2025, 10, 1)..Date.new(2025, 10, 17).end_of_day
)

puts "範囲内の購入件数: #{updated_purchases.count}"
updated_purchases.each do |purchase|
  puts "#{purchase.purchased_at.strftime('%m/%d %H:%M')}"
end