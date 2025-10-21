#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== サンプルPurchaseItemの価格詳細 ==="

# 異なるレベルのユーザーの購入を確認
sample_purchases = PurchaseItem.joins(:purchase)
                              .includes(:product, purchase: :user)
                              .limit(10)

sample_purchases.each_with_index do |item, index|
  purchase = item.purchase
  user = purchase.user
  product = item.product
  purchase_date = purchase.purchased_at
  
  puts "#{index + 1}. 購入ID: #{purchase.id}"
  puts "   購入者: #{user.display_name}"
  puts "   レベル: #{user.level&.name}"
  puts "   商品: #{product.name}"
  puts "   購入日: #{purchase_date.strftime('%Y-%m-%d')}"
  puts "   基本価格: ¥#{product.base_price}"
  puts "   unit_price: ¥#{item.unit_price}"
  puts "   seller_price: ¥#{item.seller_price}"
  
  # レベル別価格を確認
  level_price = product.product_prices.find_by(level_id: user.level.id)&.price
  puts "   レベル別価格: ¥#{level_price}"
  puts "   整合性: #{item.seller_price == level_price ? '✅' : '❌'}"
  puts
end

# 各レベルの価格設定を確認
puts "=== 製品価格設定 ==="
product = Product.first
puts "商品: #{product.name}"
puts "基本価格: ¥#{product.base_price}"
puts

Level.order(:value).each do |level|
  price = product.product_prices.find_by(level_id: level.id)&.price
  puts "#{level.name} (value: #{level.value}): ¥#{price}"
end