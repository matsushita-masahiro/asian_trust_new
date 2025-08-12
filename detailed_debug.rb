# アドバイザー5-1の詳細なインセンティブ計算デバッグ

puts "=== アドバイザー5-1 詳細インセンティブ計算デバッグ ==="

advisor = User.find(5)
puts "ユーザー: #{advisor.display_name} (ID: #{advisor.id})"
puts "現在のレベル: #{advisor.level&.name} (ID: #{advisor.level_id})"

# 8月の期間設定
start_date = Date.new(2025, 8, 1).beginning_of_day
end_date = Date.new(2025, 8, 31).end_of_day

puts "\n=== 期間: #{start_date.strftime('%Y/%m/%d')} - #{end_date.strftime('%Y/%m/%d')} ==="

total_bonus = 0

# 1. 自分の販売に対するボーナス
puts "\n--- 1. 自分の販売に対するボーナス ---"
my_purchases = advisor.purchases.includes(purchase_items: :product).where(purchased_at: start_date..end_date)
puts "自分の購入件数: #{my_purchases.count}"

my_bonus = 0
my_purchases.each do |purchase|
  puts "\n購入 ID: #{purchase.id}"
  puts "購入日: #{purchase.purchased_at.strftime('%Y/%m/%d %H:%M')}"
  
  purchase_level = advisor.level_at(purchase.purchased_at)
  puts "購入時点のレベル: #{purchase_level.name} (ID: #{purchase_level.id})"
  
  purchase.purchase_items.each do |item|
    product = item.product
    base_price = product.base_price
    my_price = product.product_prices.find_by(level_id: purchase_level.id)&.price || 0
    item_bonus = (base_price - my_price) * item.quantity
    my_bonus += item_bonus
    
    puts "  商品: #{product.name}"
    puts "  数量: #{item.quantity}"
    puts "  基本価格: #{base_price}円"
    puts "  自分の価格: #{my_price}円"
    puts "  単価差額: #{base_price - my_price}円"
    puts "  アイテムボーナス: #{item_bonus}円"
  end
end

puts "自分の販売ボーナス合計: #{my_bonus}円"
total_bonus += my_bonus

# 2. 子孫の販売に対するボーナス
puts "\n--- 2. 子孫の販売に対するボーナス ---"
descendant_ids = advisor.descendant_ids
puts "子孫ID: #{descendant_ids}"

descendant_purchases = Purchase.includes(purchase_items: :product, user: :level)
                               .where(user_id: descendant_ids)
                               .where(purchased_at: start_date..end_date)

puts "子孫の購入件数: #{descendant_purchases.count}"

descendant_bonus = 0
descendant_purchases.each do |purchase|
  puts "\n購入 ID: #{purchase.id}"
  puts "購入者: #{purchase.user.display_name} (ID: #{purchase.user.id})"
  puts "購入日: #{purchase.purchased_at.strftime('%Y/%m/%d %H:%M')}"
  
  purchase_user_level = purchase.user.level_at(purchase.purchased_at)
  my_level_at_purchase = advisor.level_at(purchase.purchased_at)
  
  puts "購入者の購入時レベル: #{purchase_user_level.name} (ID: #{purchase_user_level.id})"
  puts "自分の購入時レベル: #{my_level_at_purchase.name} (ID: #{my_level_at_purchase.id})"
  
  purchase.purchase_items.each do |item|
    product = item.product
    quantity = item.quantity
    
    purchase_user_price = product.product_prices.find_by(level_id: purchase_user_level.id)&.price || 0
    my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
    
    puts "  商品: #{product.name}"
    puts "  数量: #{quantity}"
    puts "  購入者価格: #{purchase_user_price}円"
    puts "  自分の価格: #{my_price}円"
    
    if purchase_user_price > my_price
      diff = purchase_user_price - my_price
      item_bonus = diff * quantity
      descendant_bonus += item_bonus
      puts "  階層差額: #{diff}円"
      puts "  アイテムボーナス: #{item_bonus}円"
    else
      puts "  階層差額なし（#{purchase_user_price} <= #{my_price}）"
    end
  end
end

puts "子孫の販売ボーナス合計: #{descendant_bonus}円"
total_bonus += descendant_bonus

# 3. 直下の無資格者による販売
puts "\n--- 3. 直下の無資格者による販売 ---"
unqualified_referrals = advisor.referrals.reject(&:bonus_eligible?)
puts "直下の無資格者数: #{unqualified_referrals.count}"
puts "無資格者: #{unqualified_referrals.map(&:display_name)}"

unqualified_bonus = 0
unqualified_referrals.each do |child|
  child_purchases = child.purchases.includes(purchase_items: :product).where(purchased_at: start_date..end_date)
  puts "\n#{child.display_name}の購入件数: #{child_purchases.count}"
  
  child_purchases.each do |purchase|
    my_level_at_purchase = advisor.level_at(purchase.purchased_at)
    puts "購入日: #{purchase.purchased_at.strftime('%Y/%m/%d')}, 自分のレベル: #{my_level_at_purchase.name}"
    
    purchase.purchase_items.each do |item|
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
total_bonus += unqualified_bonus

# 合計
puts "\n=== 計算結果まとめ ==="
puts "1. 自分の販売: #{my_bonus}円"
puts "2. 子孫の販売: #{descendant_bonus}円"
puts "3. 無資格者販売: #{unqualified_bonus}円"
puts "手動計算合計: #{total_bonus}円"

# システム計算結果と比較
system_bonus = advisor.bonus_in_month("2025-08")
puts "\nシステム計算結果: #{system_bonus}円"
puts "差額: #{system_bonus - total_bonus}円"

# 期待値との比較
expected_total = 300000 + 360000  # 8/7: 300000円 + 8/16: 360000円
puts "\n期待値: #{expected_total}円"
puts "システムとの差額: #{system_bonus - expected_total}円"
puts "手動計算との差額: #{total_bonus - expected_total}円"

# 重複チェック
puts "\n=== 重複チェック ==="
my_purchase_ids = my_purchases.pluck(:id)
descendant_purchase_ids = descendant_purchases.pluck(:id)
overlap = my_purchase_ids & descendant_purchase_ids

if overlap.any?
  puts "⚠️  重複している購入ID: #{overlap}"
  puts "これが重複計算の原因です！"
else
  puts "✅ 購入データに重複はありません"
end