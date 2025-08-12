# アドバイザー5-1のインセンティブ計算デバッグスクリプト

puts "=== アドバイザー5-1 インセンティブ計算デバッグ ==="

# アドバイザー5-1を取得
advisor = User.find_by(id: 5) # または適切なID
if advisor.nil?
  puts "アドバイザー5-1が見つかりません"
  exit
end

puts "ユーザー: #{advisor.display_name} (ID: #{advisor.id})"
puts "レベル: #{advisor.level&.name}"

# 8月の期間設定
start_date = Date.new(2025, 8, 1).beginning_of_day
end_date = Date.new(2025, 8, 31).end_of_day

puts "\n=== 期間: #{start_date.strftime('%Y/%m/%d')} - #{end_date.strftime('%Y/%m/%d')} ==="

# 1. 自分の販売
my_purchases = advisor.purchases.includes(purchase_items: :product).where(purchased_at: start_date..end_date)
puts "\n--- 1. 自分の販売 ---"
puts "購入件数: #{my_purchases.count}"

my_bonus = 0
my_purchases.each do |purchase|
  puts "購入日: #{purchase.purchased_at.strftime('%Y/%m/%d')}"
  purchase.purchase_items.each do |item|
    product = item.product
    base_price = product.base_price
    my_level_at_purchase = advisor.level_at(purchase.purchased_at)
    my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
    item_bonus = (base_price - my_price) * item.quantity
    my_bonus += item_bonus
    puts "  商品: #{product.name}, 数量: #{item.quantity}, ボーナス: #{item_bonus}円"
  end
end
puts "自分の販売ボーナス合計: #{my_bonus}円"

# 2. 子孫の販売
descendant_ids = advisor.descendant_ids
puts "\n--- 2. 子孫の販売 ---"
puts "子孫数: #{descendant_ids.count}"

descendant_purchases = Purchase.includes(purchase_items: :product, user: :level)
                               .where(user_id: descendant_ids)
                               .where(purchased_at: start_date..end_date)

puts "子孫の購入件数: #{descendant_purchases.count}"

descendant_bonus = 0
descendant_purchases.each do |purchase|
  puts "購入者: #{purchase.user.display_name} (ID: #{purchase.user.id})"
  puts "購入日: #{purchase.purchased_at.strftime('%Y/%m/%d')}"
  
  purchase.purchase_items.each do |item|
    purchase_user_level = purchase.user.level_at(purchase.purchased_at)
    my_level_at_purchase = advisor.level_at(purchase.purchased_at)
    
    product = item.product
    quantity = item.quantity
    
    purchase_user_price = product.product_prices.find_by(level_id: purchase_user_level.id)&.price || 0
    my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
    
    if purchase_user_price > my_price
      diff = purchase_user_price - my_price
      item_bonus = diff * quantity
      descendant_bonus += item_bonus
      puts "  商品: #{product.name}, 数量: #{quantity}, 階層差額: #{diff}円, ボーナス: #{item_bonus}円"
    else
      puts "  商品: #{product.name}, 数量: #{quantity}, 階層差額なし"
    end
  end
end
puts "子孫の販売ボーナス合計: #{descendant_bonus}円"

# 3. 直下の無資格者による販売
puts "\n--- 3. 直下の無資格者による販売 ---"
unqualified_referrals = advisor.referrals.reject(&:bonus_eligible?)
puts "直下の無資格者数: #{unqualified_referrals.count}"

unqualified_bonus = 0
unqualified_referrals.each do |child|
  child_purchases = child.purchases.includes(purchase_items: :product).where(purchased_at: start_date..end_date)
  puts "#{child.display_name}の購入件数: #{child_purchases.count}"
  
  child_purchases.each do |purchase|
    purchase.purchase_items.each do |item|
      my_level_at_purchase = advisor.level_at(purchase.purchased_at)
      product = item.product
      base_price = product.base_price
      my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
      diff = base_price - my_price
      if diff.positive?
        item_bonus = diff * item.quantity
        unqualified_bonus += item_bonus
        puts "  商品: #{product.name}, 数量: #{item.quantity}, ボーナス: #{item_bonus}円"
      end
    end
  end
end
puts "無資格者販売ボーナス合計: #{unqualified_bonus}円"

# 合計
total_calculated = my_bonus + descendant_bonus + unqualified_bonus
puts "\n=== 計算結果 ==="
puts "1. 自分の販売: #{my_bonus}円"
puts "2. 子孫の販売: #{descendant_bonus}円"
puts "3. 無資格者販売: #{unqualified_bonus}円"
puts "合計: #{total_calculated}円"

# システムの計算結果と比較
system_bonus = advisor.bonus_in_month("2025-08")
puts "\nシステム計算結果: #{system_bonus}円"
puts "差額: #{system_bonus - total_calculated}円"

if system_bonus != total_calculated
  puts "\n⚠️  計算結果に差異があります！"
else
  puts "\n✅ 計算結果が一致しています"
end