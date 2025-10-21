#!/usr/bin/env ruby
require_relative 'config/environment'

# 吉田博文の特定の購入に対する鈴木愛美さんのインセンティブを詳しく確認
suzuki = User.find_by(name: "鈴木愛美")
yoshida = User.find_by(name: "吉田博文")

puts "=== 吉田博文の購入に対する鈴木愛美さんのインセンティブ詳細 ==="

# 吉田博文の10月の購入を取得
yoshida_purchases = PurchaseItem.joins(:purchase)
                               .where(purchases: { user_id: yoshida.id, purchased_at: Date.new(2025, 10, 1)..Date.new(2025, 10, 31) })
                               .includes(:product, purchase: :user)

puts "吉田博文の10月の購入件数: #{yoshida_purchases.count}"

yoshida_purchases.each_with_index do |item, index|
  puts "\n--- 購入 #{index + 1} ---"
  purchase = item.purchase
  purchase_date = purchase.purchased_at
  
  puts "購入日: #{purchase_date}"
  puts "商品: #{item.product.name}"
  puts "数量: #{item.quantity}"
  puts "単価: ¥#{item.unit_price}"
  
  # 経路確認
  path_to_suzuki = yoshida.path_to_ancestor(suzuki)
  puts "経路: #{path_to_suzuki.map(&:display_name).join(' -> ')}"
  
  # 鈴木愛美さんのレベルと価格
  suzuki_level = suzuki.level_at(purchase_date)
  suzuki_price = item.product.product_prices.find_by(level_id: suzuki_level.id)&.price || 0
  puts "鈴木愛美さんのレベル: #{suzuki_level&.name}"
  puts "鈴木愛美さんの価格: ¥#{suzuki_price}"
  
  # 中間の受給資格者を確認
  if path_to_suzuki.length > 2
    intermediate_path = path_to_suzuki[1..-2]
    eligible_user = intermediate_path.reverse.find(&:bonus_eligible?)
    
    if eligible_user
      eligible_level = eligible_user.level_at(purchase_date)
      eligible_price = item.product.product_prices.find_by(level_id: eligible_level.id)&.price || 0
      puts "中間の受給資格者: #{eligible_user.display_name} (#{eligible_level&.name})"
      puts "中間の受給資格者の価格: ¥#{eligible_price}"
      
      # インセンティブ計算
      if eligible_price > suzuki_price
        incentive_unit = eligible_price - suzuki_price
        total_incentive = incentive_unit * item.quantity
        puts "インセンティブ計算: ¥#{eligible_price} - ¥#{suzuki_price} = ¥#{incentive_unit}"
        puts "総インセンティブ: ¥#{incentive_unit} × #{item.quantity} = ¥#{total_incentive}"
      else
        puts "インセンティブなし (#{eligible_price} <= #{suzuki_price})"
      end
    else
      # 中間に受給資格者がいない場合
      yoshida_level = yoshida.level_at(purchase_date)
      yoshida_price = item.product.product_prices.find_by(level_id: yoshida_level.id)&.price || 0
      puts "中間に受給資格者なし"
      puts "吉田博文の価格: ¥#{yoshida_price}"
      
      if yoshida_price > suzuki_price
        incentive_unit = yoshida_price - suzuki_price
        total_incentive = incentive_unit * item.quantity
        puts "インセンティブ計算: ¥#{yoshida_price} - ¥#{suzuki_price} = ¥#{incentive_unit}"
        puts "総インセンティブ: ¥#{incentive_unit} × #{item.quantity} = ¥#{total_incentive}"
      else
        puts "インセンティブなし (#{yoshida_price} <= #{suzuki_price})"
      end
    end
  end
end