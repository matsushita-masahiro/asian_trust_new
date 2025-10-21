#!/usr/bin/env ruby
require_relative 'config/environment'

puts "🔍 Checking all purchases by 田中美咲's descendants in October 2025..."

tanaka = User.find_by(name: "田中美咲")
start_date = Date.new(2025, 10, 1)
end_date = Date.new(2025, 10, 31)

descendant_ids = tanaka.descendant_ids
puts "👥 Total descendants: #{descendant_ids.count}"

# 10月の全購入を取得
purchases = Purchase.where(user_id: descendant_ids, purchased_at: start_date..end_date)
                   .includes(:user, :purchase_items => :product)

puts "\n🛒 All purchases in October 2025:"
total_items = 0
purchases.each do |purchase|
  user = purchase.user
  purchase.purchase_items.each do |item|
    total_items += item.quantity
    puts "#{purchase.purchased_at.strftime('%m/%d')} - #{user.name} (#{user.level&.name}): #{item.product.name} x#{item.quantity} @ ¥#{item.unit_price}"
  end
end

puts "\n📊 Summary:"
puts "Total purchases: #{purchases.count}"
puts "Total items: #{total_items}"

# 期待される田中美咲のインセンティブを手動計算
expected_bonus = 0

# 鈴木愛美の購入: 12個 × 2,000円 = 24,000円
suzuki_purchases = purchases.joins(:user).where(users: { name: "鈴木愛美" })
suzuki_items = suzuki_purchases.sum { |p| p.purchase_items.sum(&:quantity) }
suzuki_bonus = suzuki_items * 2000
expected_bonus += suzuki_bonus
puts "鈴木愛美: #{suzuki_items}個 × ¥2,000 = ¥#{suzuki_bonus}"

# 中村結衣の購入: 42個 × 2,000円 = 84,000円
nakamura_purchases = purchases.joins(:user).where(users: { name: "中村結衣" })
nakamura_items = nakamura_purchases.sum { |p| p.purchase_items.sum(&:quantity) }
nakamura_bonus = nakamura_items * 2000
expected_bonus += nakamura_bonus
puts "中村結衣: #{nakamura_items}個 × ¥2,000 = ¥#{nakamura_bonus}"

# 林美里の購入: 8個 × 2,000円 = 16,000円
hayashi_purchases = purchases.joins(:user).where(users: { name: "林美里" })
hayashi_items = hayashi_purchases.sum { |p| p.purchase_items.sum(&:quantity) }
hayashi_bonus = hayashi_items * 2000
expected_bonus += hayashi_bonus
puts "林美里: #{hayashi_items}個 × ¥2,000 = ¥#{hayashi_bonus}"

puts "\n💰 Expected total bonus: ¥#{expected_bonus}"
puts "💰 Actual bonus_in_period: ¥#{tanaka.bonus_in_period(start_date, end_date)}"
puts "💰 Difference: ¥#{tanaka.bonus_in_period(start_date, end_date) - expected_bonus}"