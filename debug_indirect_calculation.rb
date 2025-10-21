#!/usr/bin/env ruby
require_relative 'config/environment'

user = User.find_by(name: "中村結衣")
service = IncentiveCalculationService.from_month_string(user, "2025-10")

# 福田一郎の10月10日の購入を詳しく調べる
customer = User.find_by(name: "福田一郎")
purchase_item = PurchaseItem.joins(:purchase)
                           .where(purchases: { user_id: customer.id, purchased_at: service.start_date..service.end_date })
                           .includes(:product, purchase: :user)
                           .first

puts "=== 福田一郎の購入詳細デバッグ ==="
puts "購入者: #{purchase_item.purchase.user.display_name}"
puts "商品: #{purchase_item.product.name}"
puts "購入日: #{purchase_item.purchase.purchased_at}"
puts "数量: #{purchase_item.quantity}"

purchase = purchase_item.purchase
purchase_date = purchase.purchased_at
purchase_user = purchase.user
my_level_at_purchase = user.level_at(purchase_date)

puts "\n=== 経路と資格確認 ==="
path_to_me = purchase_user.path_to_ancestor(user)
puts "経路: #{path_to_me.map(&:display_name).join(' -> ')}"
puts "経路の長さ: #{path_to_me.length}"

# 直下位ユーザーかどうか
is_direct = path_to_me.length == 2
puts "直下位ユーザー: #{is_direct}"

if is_direct
  puts "直下位ユーザーとして処理"
  purchase_user_level = purchase_user.level_at(purchase_date)
  eligible_user_price = purchase_item.product.product_prices.find_by(level_id: purchase_user_level.id)&.price || 0
  puts "購入者の価格: ¥#{eligible_user_price} (#{purchase_user_level&.name})"
else
  puts "間接的な子孫として処理"
  # 自分を除いた経路でインセンティブ受領資格者を探す
  path_without_me = path_to_me[0..-2]
  puts "自分を除いた経路: #{path_without_me.map(&:display_name).join(' -> ')}"
  
  eligible_users = path_without_me.reverse
  puts "逆順の経路: #{eligible_users.map(&:display_name).join(' -> ')}"
  
  eligible_users.each_with_index do |path_user, i|
    puts "  #{i}: #{path_user.display_name} - インセンティブ受領資格: #{path_user.bonus_eligible?}"
  end
  
  eligible_user_in_path = eligible_users.find(&:bonus_eligible?)
  puts "見つかった中間資格者: #{eligible_user_in_path ? eligible_user_in_path.display_name : 'なし'}"
  
  if eligible_user_in_path
    # 中間にインセンティブ受領資格者がいる場合
    eligible_user_level = eligible_user_in_path.level_at(purchase_date)
    eligible_user_price = purchase_item.product.product_prices.find_by(level_id: eligible_user_level.id)&.price || 0
    puts "中間資格者の価格: ¥#{eligible_user_price} (#{eligible_user_level&.name})"
  else
    # 中間にインセンティブ受領資格者がいない場合（購入者の価格を使用）
    purchase_user_level = purchase_user.level_at(purchase_date)
    eligible_user_price = purchase_item.product.product_prices.find_by(level_id: purchase_user_level.id)&.price || 0
    puts "購入者の価格: ¥#{eligible_user_price} (#{purchase_user_level&.name})"
  end
end

my_price = purchase_item.product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
puts "自分の価格: ¥#{my_price} (#{my_level_at_purchase&.name})"

puts "\n=== 計算結果 ==="
if eligible_user_price > my_price
  incentive_unit = eligible_user_price - my_price
  item_incentive = incentive_unit * purchase_item.quantity
  puts "インセンティブ: ¥#{incentive_unit} × #{purchase_item.quantity} = ¥#{item_incentive}"
else
  puts "インセンティブなし (#{eligible_user_price} <= #{my_price})"
end

# 美容サロン花音の詳細確認
salon = User.find_by(name: "美容サロン花音")
puts "\n=== 美容サロン花音の詳細 ==="
puts "名前: #{salon.display_name}"
puts "レベル: #{salon.level&.name}"
puts "インセンティブ受領資格: #{salon.bonus_eligible?}"