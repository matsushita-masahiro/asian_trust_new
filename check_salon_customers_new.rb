#!/usr/bin/env ruby
require_relative 'config/environment'

# 中村結衣さんの全子孫と購入データを確認
user = User.find_by(name: "中村結衣")
puts "=== #{user.display_name}さんの子孫と購入データ ==="

# 全子孫を取得
descendant_ids = user.descendant_ids
descendants = User.where(id: descendant_ids).includes(:level)

puts "子孫ユーザー数: #{descendants.count}"
puts

descendants.each do |descendant|
  puts "#{descendant.display_name} (#{descendant.level&.name}) - ID: #{descendant.id}"
  
  # 10月の購入を確認
  october_purchases = Purchase.where(
    user_id: descendant.id,
    purchased_at: Date.new(2025, 10, 1)..Date.new(2025, 10, 31)
  ).includes(:purchase_items => :product)
  
  if october_purchases.any?
    october_purchases.each do |purchase|
      total = purchase.purchase_items.sum { |item| item.unit_price * item.quantity }
      puts "  購入: ¥#{total} (#{purchase.purchased_at.strftime('%m/%d %H:%M')})"
      purchase.purchase_items.each do |item|
        puts "    #{item.product.name} × #{item.quantity}"
      end
    end
  else
    puts "  10月の購入なし"
  end
  puts
end

# サロンのお客様を特に確認
puts "=== サロンのお客様の詳細 ==="
salon_customers = descendants.joins(:level).where(levels: { name: "お客様" })
                            .joins("JOIN users AS parents ON users.referred_by_id = parents.id")
                            .joins("JOIN levels AS parent_levels ON parents.level_id = parent_levels.id")
                            .where("parent_levels.name IN ('サロン', 'クリニック')")

salon_customers.each do |customer|
  parent = User.find(customer.referred_by_id)
  puts "#{customer.display_name} -> #{parent.display_name} (#{parent.level&.name})"
  
  # 経路を確認
  path = customer.path_to_ancestor(user)
  puts "  経路: #{path ? path.map(&:display_name).join(' -> ') : 'なし'}"
  
  # 10月の購入
  october_purchases = Purchase.where(
    user_id: customer.id,
    purchased_at: Date.new(2025, 10, 1)..Date.new(2025, 10, 31)
  ).includes(:purchase_items => :product)
  
  october_purchases.each do |purchase|
    puts "  購入: #{purchase.purchased_at.strftime('%m/%d %H:%M')}"
    purchase.purchase_items.each do |item|
      puts "    #{item.product.name} × #{item.quantity} = ¥#{item.unit_price * item.quantity}"
    end
  end
  puts
end