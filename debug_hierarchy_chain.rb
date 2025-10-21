#!/usr/bin/env ruby
require_relative 'config/environment'

puts "🔍 Debugging hierarchy chain construction..."

# 中村結衣の購入に対する田中美咲のボーナス計算をテスト
tanaka = User.find_by(name: "田中美咲")
suzuki = User.find_by(name: "鈴木愛美")
nakamura = User.find_by(name: "中村結衣")

puts "👤 田中美咲 (#{tanaka.level&.name}) - Price: ¥36,000"
puts "👤 鈴木愛美 (#{suzuki.level&.name}) - Price: ¥38,000"
puts "👤 中村結衣 (#{nakamura.level&.name}) - Price: ¥40,000"

puts "\n🔗 Hierarchy check:"
puts "中村結衣.referred_by_id: #{nakamura.referred_by_id} (should be 鈴木愛美's id: #{suzuki.id})"
puts "鈴木愛美.referred_by_id: #{suzuki.referred_by_id} (should be 田中美咲's id: #{tanaka.id})"

# 階層チェーンを手動で構築してテスト
purchase_user = nakamura
target_user = tanaka

puts "\n🔗 Building bonus chain from #{purchase_user.name} to #{target_user.name}:"

bonus_chain = [purchase_user]
current = purchase_user
puts "Start: #{current.name}"

while current.referred_by_id
  current = User.find(current.referred_by_id)
  puts "Next: #{current.name} (bonus_eligible: #{current.bonus_eligible?})"
  bonus_chain << current if current.bonus_eligible?
  break if current == target_user
end

puts "\n📋 Final bonus chain:"
bonus_chain.each_with_index do |user, index|
  puts "#{index}: #{user.name} (#{user.level&.name})"
end

# 隣接する階層間の価格差を計算
product = Product.find_by(name: "骨髄幹細胞培培養上清液")
purchase_date = Date.new(2025, 10, 1)

puts "\n💰 Price differences:"
bonus_chain.each_cons(2) do |lower, upper|
  lower_level = lower.level_at(purchase_date)
  upper_level = upper.level_at(purchase_date)
  
  lower_price = product.product_prices.find_by(level_id: lower_level.id)&.price || 0
  upper_price = product.product_prices.find_by(level_id: upper_level.id)&.price || 0
  
  diff = lower_price - upper_price
  puts "#{lower.name} (¥#{lower_price}) -> #{upper.name} (¥#{upper_price}) = ¥#{diff}"
  
  if upper == target_user
    puts "  ✅ This is 田中美咲's bonus: ¥#{diff} per item"
    puts "  ✅ For 14 items: ¥#{diff * 14}"
  end
end