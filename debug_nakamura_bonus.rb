#!/usr/bin/env ruby
require_relative 'config/environment'

puts "🔍 Debugging 中村結衣's bonus calculation..."

nakamura = User.find_by(name: "中村結衣")
if nakamura.nil?
  puts "❌ 中村結衣 not found"
  exit 1
end

puts "👤 User: #{nakamura.name}"
puts "📊 Level: #{nakamura.level&.name}"
puts "🎯 Bonus eligible: #{nakamura.bonus_eligible?}"

# 期間設定
start_date = Date.new(2025, 10, 1)
end_date = Date.new(2025, 10, 31)

puts "\n📅 Period: #{start_date} to #{end_date}"

# 自分の購入データ
my_purchases = nakamura.purchases.where(purchased_at: start_date..end_date)
puts "\n🛒 My purchases: #{my_purchases.count}"

my_total_bonus = 0
my_purchases.each do |purchase|
  purchase.purchase_items.each do |item|
    bonus = nakamura.bonus_for_purchase_item(item)
    my_total_bonus += bonus
    puts "  - #{item.product.name} x#{item.quantity}: ¥#{bonus.to_i}"
  end
end
puts "💰 My purchase bonus total: ¥#{my_total_bonus.to_i}"

# 子孫の購入データ
descendant_ids = nakamura.descendant_ids
puts "\n👥 All Descendants: #{descendant_ids.count}"
descendant_ids.each do |desc_id|
  desc_user = User.find(desc_id)
  puts "  - #{desc_user.name} (#{desc_user.level&.name})"
end

# 直下無資格者
direct_non_eligible = nakamura.referrals.reject(&:bonus_eligible?)
direct_non_eligible_ids = direct_non_eligible.pluck(:id)
puts "\n👥 Direct non-eligible: #{direct_non_eligible.count}"
direct_non_eligible.each do |user|
  puts "  - #{user.name} (#{user.level&.name})"
end

# 実際の子孫計算対象
filtered_descendant_ids = descendant_ids.reject { |uid| uid == nakamura.id || direct_non_eligible_ids.include?(uid) }
puts "\n👥 Filtered descendants for calculation: #{filtered_descendant_ids.count}"
filtered_descendant_ids.each do |desc_id|
  desc_user = User.find(desc_id)
  puts "  - #{desc_user.name} (#{desc_user.level&.name})"
end

descendant_purchases = Purchase.where(user_id: descendant_ids, purchased_at: start_date..end_date)
puts "\n🛒 All descendant purchases: #{descendant_purchases.count}"

filtered_descendant_purchases = Purchase.where(user_id: filtered_descendant_ids, purchased_at: start_date..end_date)
puts "🛒 Filtered descendant purchases: #{filtered_descendant_purchases.count}"

descendant_total_bonus = 0
filtered_descendant_purchases.each do |purchase|
  purchase.purchase_items.each do |item|
    purchase_user_level = purchase.user.level_at(purchase.purchased_at)
    nakamura_level_at_purchase = nakamura.level_at(purchase.purchased_at)
    
    product = item.product
    purchase_user_price = product.product_prices.find_by(level_id: purchase_user_level.id)&.price || 0
    nakamura_price = product.product_prices.find_by(level_id: nakamura_level_at_purchase.id)&.price || 0
    
    if purchase_user_price > nakamura_price
      diff = purchase_user_price - nakamura_price
      bonus = diff * item.quantity
      descendant_total_bonus += bonus
      puts "  - #{purchase.user.name}: #{item.product.name} x#{item.quantity}"
      puts "    Purchase price: ¥#{purchase_user_price}, Nakamura price: ¥#{nakamura_price}"
      puts "    Bonus: ¥#{bonus.to_i}"
    end
  end
end
puts "💰 Descendant bonus total: ¥#{descendant_total_bonus.to_i}"

# 直下無資格者の購入データ
puts "\n👥 Direct non-eligible referrals: #{direct_non_eligible.count}"
direct_non_eligible.each do |ref|
  puts "  - #{ref.name} (#{ref.level&.name})"
end

referral_total_bonus = 0
direct_non_eligible.each do |child|
  child_purchases = child.purchases.where(purchased_at: start_date..end_date)
  child_purchases.each do |purchase|
    purchase.purchase_items.each do |item|
      purchase_date = item.purchase.purchased_at
      nakamura_level_at_purchase = nakamura.level_at(purchase_date)
      product = item.product
      base_price = product.base_price
      nakamura_price = product.product_prices.find_by(level_id: nakamura_level_at_purchase.id)&.price || 0
      diff = base_price - nakamura_price
      if diff.positive?
        bonus = diff * item.quantity
        referral_total_bonus += bonus
        puts "  - #{child.name}: #{item.product.name} x#{item.quantity}"
        puts "    Base price: ¥#{base_price}, Nakamura price: ¥#{nakamura_price}"
        puts "    Bonus: ¥#{bonus.to_i}"
      end
    end
  end
end
puts "💰 Direct referral bonus total: ¥#{referral_total_bonus.to_i}"

# 最終計算
total_calculated = my_total_bonus + descendant_total_bonus + referral_total_bonus
actual_bonus = nakamura.bonus_in_period(start_date, end_date)

puts "\n📊 Summary:"
puts "My purchase bonus: ¥#{my_total_bonus.to_i}"
puts "Descendant bonus: ¥#{descendant_total_bonus.to_i}"
puts "Direct referral bonus: ¥#{referral_total_bonus.to_i}"
puts "Total calculated: ¥#{total_calculated.to_i}"
puts "Actual bonus_in_period: ¥#{actual_bonus.to_i}"
puts "Expected: ¥50,000"
puts "Difference: ¥#{(actual_bonus - 50000).to_i}"