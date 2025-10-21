#!/usr/bin/env ruby
require_relative 'config/environment'

# 中村結衣さん（ID: 11）の階層差額計算をデバッグ
user = User.find(11)
puts "=== #{user.display_name}さんの階層差額計算デバッグ ==="

service = IncentiveCalculationService.from_month_string(user, "2025-10")

# すべての子孫を取得
descendant_user_ids = user.descendant_ids.reject { |uid| uid == user.id }
puts "子孫ユーザーID: #{descendant_user_ids}"

descendant_purchase_items = PurchaseItem.joins(:purchase)
                                       .where(purchases: { user_id: descendant_user_ids, purchased_at: service.start_date..service.end_date })
                                       .includes(:product, purchase: :user)

puts "子孫の購入アイテム数: #{descendant_purchase_items.count}"

descendant_purchase_items.each do |item|
  purchase = item.purchase
  purchase_date = purchase.purchased_at
  purchase_user = purchase.user
  my_level_at_purchase = user.level_at(purchase_date)
  
  puts "\n--- 購入アイテム ---"
  puts "購入者: #{purchase_user.display_name} (ID: #{purchase_user.id})"
  puts "商品: #{item.product.name}"
  puts "購入日: #{purchase_date}"
  puts "数量: #{item.quantity}"
  
  # 購入者から自分までの経路を確認
  path_to_me = purchase_user.path_to_ancestor(user)
  puts "経路: #{path_to_me ? path_to_me.map(&:display_name).join(' -> ') : 'なし'}"
  
  if path_to_me
    # 自分を除いた経路でインセンティブ受領資格者を探す
    eligible_user_in_path = path_to_me[0..-2].reverse.find(&:bonus_eligible?)
    
    puts "中間のインセンティブ受領資格者: #{eligible_user_in_path ? eligible_user_in_path.display_name : 'なし'}"
    
    if eligible_user_in_path
      # 中間にインセンティブ受領資格者がいる場合
      eligible_user_level = eligible_user_in_path.level_at(purchase_date)
      eligible_user_price = item.product.product_prices.find_by(level_id: eligible_user_level.id)&.price || 0
      puts "中間資格者の価格: ¥#{eligible_user_price} (#{eligible_user_level&.name})"
    else
      # 中間にインセンティブ受領資格者がいない場合（購入者の価格を使用）
      purchase_user_level = purchase_user.level_at(purchase_date)
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
  else
    puts "経路が見つからないためスキップ"
  end
end