#!/usr/bin/env ruby
require_relative 'config/environment'

# 田中美咲さんのインセンティブ計算をデバッグ
tanaka = User.find_by(name: "田中美咲")
puts "=== #{tanaka.display_name}さんのインセンティブ計算デバッグ ==="
puts "レベル: #{tanaka.level&.name}"
puts "インセンティブ受領資格: #{tanaka.bonus_eligible?}"
puts

# 田中美咲さんの価格を確認
product = Product.first
tanaka_price = product.product_prices.find_by(level_id: tanaka.level.id)&.price || 0
puts "田中美咲さんの価格: ¥#{tanaka_price}"
puts

# 10月の購入データを確認
purchases = Purchase.where(purchased_at: Date.new(2025, 10, 1)..Date.new(2025, 10, 31))
                   .includes(:user, :purchase_items => :product)
                   .order(:purchased_at)

puts "=== 10月の全購入データ ===\n"
purchases.each_with_index do |purchase, index|
  user = purchase.user
  puts "#{index + 1}. #{user.display_name} (#{user.level&.name})"
  puts "   購入日: #{purchase.purchased_at.strftime('%Y/%m/%d')}"
  
  purchase.purchase_items.each do |item|
    puts "   商品: #{item.product.name}"
    puts "   数量: #{item.quantity}"
    puts "   単価: ¥#{item.unit_price}"
    puts "   seller_price: ¥#{item.seller_price}"
    
    # 田中美咲さんのインセンティブを計算
    incentive_unit = tanaka.incentive_unit_price_for_item(item)
    total_incentive = tanaka.bonus_for_purchase_item(item)
    
    puts "   田中美咲さんのインセンティブ単価: ¥#{incentive_unit}"
    puts "   田中美咲さんのインセンティブ: ¥#{total_incentive}"
    
    # 手動計算で確認
    purchase_user_price = item.seller_price || 0
    manual_incentive_unit = purchase_user_price - tanaka_price
    manual_total = manual_incentive_unit * item.quantity
    
    puts "   手動計算: ¥#{purchase_user_price} - ¥#{tanaka_price} = ¥#{manual_incentive_unit}"
    puts "   手動計算総額: ¥#{manual_incentive_unit} × #{item.quantity} = ¥#{manual_total}"
    
    if incentive_unit != manual_incentive_unit
      puts "   ❌ 計算不一致！"
    else
      puts "   ✅ 計算一致"
    end
  end
  puts
end

# 田中美咲さんの子孫を確認
puts "=== 田中美咲さんの子孫 ==="
descendant_ids = tanaka.descendant_ids
descendants = User.where(id: descendant_ids).includes(:level)

descendants.each do |descendant|
  path = descendant.path_to_ancestor(tanaka)
  puts "#{descendant.display_name} (#{descendant.level&.name})"
  puts "  経路: #{path ? path.map(&:display_name).join(' -> ') : 'なし'}"
  puts "  経路の長さ: #{path ? path.length : 0}"
  
  # このユーザーの価格
  descendant_price = product.product_prices.find_by(level_id: descendant.level.id)&.price || 0
  puts "  価格: ¥#{descendant_price}"
  puts
end