#!/usr/bin/env ruby
require_relative 'config/environment'

# サロンのお客様の経路を確認
user = User.find(11) # 中村結衣
salon = User.find(23) # 美容サロン花音
customer1 = User.find(101) # 福田一郎
customer2 = User.find(102) # 岩田美咲

puts "=== 経路確認 ==="
puts "中村結衣: #{user.display_name}"
puts "美容サロン花音: #{salon.display_name}"
puts "福田一郎: #{customer1.display_name}"
puts "岩田美咲: #{customer2.display_name}"
puts

# 経路を確認
path1 = customer1.path_to_ancestor(user)
path2 = customer2.path_to_ancestor(user)

puts "福田一郎 -> 中村結衣の経路:"
if path1
  puts "  #{path1.map(&:display_name).join(' -> ')}"
  puts "  経路の長さ: #{path1.length}"
else
  puts "  経路なし"
end

puts "岩田美咲 -> 中村結衣の経路:"
if path2
  puts "  #{path2.map(&:display_name).join(' -> ')}"
  puts "  経路の長さ: #{path2.length}"
else
  puts "  経路なし"
end
puts

# 美容サロン花音のインセンティブ受領資格を確認
puts "美容サロン花音のインセンティブ受領資格: #{salon.bonus_eligible?}"
puts "美容サロン花音のレベル: #{salon.level&.name}"
puts

# 実際の計算をシミュレート
service = IncentiveCalculationService.from_month_string(user, "2025-10")

# 福田一郎の購入を確認
customer1_purchases = PurchaseItem.joins(:purchase)
                                 .where(purchases: { user_id: customer1.id, purchased_at: service.start_date..service.end_date })
                                 .includes(:product, purchase: :user)

puts "=== 福田一郎の購入詳細 ==="
customer1_purchases.each do |item|
  purchase = item.purchase
  purchase_date = purchase.purchased_at
  my_level_at_purchase = user.level_at(purchase_date)
  
  puts "商品: #{item.product.name}"
  puts "購入日: #{purchase_date}"
  
  # 経路確認
  path_to_me = customer1.path_to_ancestor(user)
  puts "経路: #{path_to_me ? path_to_me.map(&:display_name).join(' -> ') : 'なし'}"
  
  if path_to_me && path_to_me.length > 2
    # 間接的な子孫の場合
    puts "間接的な子孫として処理"
    eligible_user_in_path = path_to_me[0..-2].reverse.find(&:bonus_eligible?)
    puts "中間のインセンティブ受領資格者: #{eligible_user_in_path ? eligible_user_in_path.display_name : 'なし'}"
    
    if eligible_user_in_path
      eligible_user_level = eligible_user_in_path.level_at(purchase_date)
      eligible_user_price = item.product.product_prices.find_by(level_id: eligible_user_level.id)&.price || 0
      puts "中間資格者の価格: ¥#{eligible_user_price} (#{eligible_user_level&.name})"
    else
      purchase_user_level = customer1.level_at(purchase_date)
      eligible_user_price = item.product.product_prices.find_by(level_id: purchase_user_level.id)&.price || 0
      puts "購入者の価格: ¥#{eligible_user_price} (#{purchase_user_level&.name})"
    end
    
    my_price = item.product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
    puts "自分の価格: ¥#{my_price} (#{my_level_at_purchase&.name})"
    
    if eligible_user_price > my_price
      incentive_unit = eligible_user_price - my_price
      item_incentive = incentive_unit * item.quantity
      puts "インセンティブ: ¥#{incentive_unit} × #{item.quantity} = ¥#{item_incentive}"
    else
      puts "インセンティブなし (#{eligible_user_price} <= #{my_price})"
    end
  end
  puts
end