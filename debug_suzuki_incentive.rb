#!/usr/bin/env ruby
require_relative 'config/environment'

# 鈴木愛美さんのインセンティブ計算をデバッグ
suzuki = User.find_by(name: "鈴木愛美")
puts "=== #{suzuki.display_name}さんのインセンティブ計算デバッグ ==="
puts "レベル: #{suzuki.level&.name}"
puts "インセンティブ受領資格: #{suzuki.bonus_eligible?}"
puts

# 2025年10月のインセンティブ計算
service = IncentiveCalculationService.from_month_string(suzuki, "2025-10")
result = service.calculate_detailed_incentives

puts "=== 計算結果 ==="
puts "総インセンティブ: ¥#{result[:total]}"
puts "自己購入インセンティブ: ¥#{result[:details][:own_sales]}"
puts "階層差額インセンティブ: ¥#{result[:details][:descendant_sales]}"
puts "対象購入件数: #{result[:details][:purchase_count]}"
puts

# 階層別売上を確認
puts "=== 階層別売上 ==="
hierarchy_data = service.calculate_hierarchy_sales
hierarchy_data.each do |user_id, data|
  puts "#{data[:user_name]} (#{data[:level]}): 売上¥#{data[:sales_total]}, インセンティブ¥#{data[:incentive_amount]}"
end
puts

# 鈴木愛美さんの直下位ユーザーを確認
puts "=== 直下位ユーザーの詳細 ==="
suzuki.referrals.each do |referral|
  puts "#{referral.display_name} (#{referral.level&.name})"
  puts "  インセンティブ受領資格: #{referral.bonus_eligible?}"
  
  # このユーザーの購入を確認
  purchase_items = PurchaseItem.joins(:purchase)
                              .where(purchases: { user_id: referral.id, purchased_at: service.start_date..service.end_date })
                              .includes(:product, purchase: :user)
  
  total_sales = 0
  total_incentive = 0
  
  purchase_items.each do |item|
    purchase_date = item.purchase.purchased_at
    suzuki_level_at_purchase = suzuki.level_at(purchase_date)
    referral_level_at_purchase = referral.level_at(purchase_date)
    
    product = item.product
    base_price = product.base_price
    suzuki_price = product.product_prices.find_by(level_id: suzuki_level_at_purchase.id)&.price || 0
    referral_price = product.product_prices.find_by(level_id: referral_level_at_purchase.id)&.price || 0
    
    item_sales = item.unit_price * item.quantity
    total_sales += item_sales
    
    if referral.bonus_eligible?
      # 受給資格がある場合は、referralが自分で受け取るので鈴木愛美さんには入らない
      puts "  商品: #{product.name} (#{purchase_date.strftime('%m/%d')})"
      puts "    売上: ¥#{item_sales}"
      puts "    #{referral.display_name}が受給資格ありのため、鈴木愛美さんのインセンティブなし"
    else
      # 受給資格がない場合は、鈴木愛美さんが階層差額を受け取る
      incentive_unit = referral_price - suzuki_price
      item_incentive = incentive_unit * item.quantity
      total_incentive += item_incentive
      
      puts "  商品: #{product.name} (#{purchase_date.strftime('%m/%d')})"
      puts "    売上: ¥#{item_sales}"
      puts "    基本価格: ¥#{base_price}"
      puts "    #{referral.display_name}の価格: ¥#{referral_price} (#{referral_level_at_purchase&.name})"
      puts "    鈴木愛美さんの価格: ¥#{suzuki_price} (#{suzuki_level_at_purchase&.name})"
      puts "    階層差額: ¥#{incentive_unit} × #{item.quantity} = ¥#{item_incentive}"
    end
  end
  
  puts "  合計売上: ¥#{total_sales}"
  puts "  合計インセンティブ: ¥#{total_incentive}"
  puts
end

# 鈴木愛美さんの子孫全体を確認
puts "=== 全子孫の購入確認 ==="
descendant_ids = suzuki.descendant_ids.reject { |uid| uid == suzuki.id }
descendants = User.where(id: descendant_ids).includes(:level)

descendants.each do |descendant|
  purchase_items = PurchaseItem.joins(:purchase)
                              .where(purchases: { user_id: descendant.id, purchased_at: service.start_date..service.end_date })
                              .includes(:product, purchase: :user)
  
  if purchase_items.any?
    total_sales = purchase_items.sum { |item| item.unit_price * item.quantity }
    puts "#{descendant.display_name} (#{descendant.level&.name}): ¥#{total_sales}"
  end
end