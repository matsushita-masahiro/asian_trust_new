# アドバイザー5-1のボーナス計算デバッグ（病院9の販売による階層差額）

puts "=== アドバイザー5-1 ボーナス計算デバッグ ==="

advisor = User.find(19)  # 正しいアドバイザー5-1のID
puts "ユーザー: #{advisor.display_name} (ID: #{advisor.id})"
puts "現在のレベル: #{advisor.level&.name}"

# 病院9を確認
hospital9 = User.find_by(name: '病院9') || User.find(9)
if hospital9
  puts "病院9: #{hospital9.display_name} (ID: #{hospital9.id}), レベル: #{hospital9.level&.name}"
  puts "病院9の紹介者: #{hospital9.referrer&.display_name}"
else
  puts "病院9が見つかりません"
end

# 8月の期間設定
start_date = Date.new(2025, 8, 1).beginning_of_day
end_date = Date.new(2025, 8, 31).end_of_day

puts "\n=== bonus_in_period メソッドの詳細デバッグ ==="

# (1) 自分の販売
puts "\n--- (1) 自分の販売 ---"
my_purchase_items = PurchaseItem.joins(:purchase)
                               .where(purchases: { user_id: advisor.id, purchased_at: start_date..end_date })
                               .includes(:product, purchase: :user)

puts "自分の購入アイテム数: #{my_purchase_items.count}"
my_bonus_total = 0

my_purchase_items.each do |item|
  bonus = advisor.bonus_for_purchase_item(item)
  my_bonus_total += bonus
  puts "  購入ID: #{item.purchase.id}, 商品: #{item.product.name}, 数量: #{item.quantity}, ボーナス: #{bonus}円"
end

puts "自分の販売ボーナス合計: #{my_bonus_total}円"

# (2) 子孫の販売
puts "\n--- (2) 子孫の販売 ---"
descendant_user_ids = advisor.descendant_ids.reject { |uid| uid == advisor.id }
puts "子孫ユーザーID: #{descendant_user_ids}"

descendant_bonus_total = 0

if descendant_user_ids.any?
  descendant_purchase_items = PurchaseItem.joins(:purchase)
                                         .where(purchases: { user_id: descendant_user_ids, purchased_at: start_date..end_date })
                                         .includes(:product, purchase: :user)
  
  puts "子孫の購入アイテム数: #{descendant_purchase_items.count}"
  
  descendant_purchase_items.each do |item|
    purchase = item.purchase
    purchase_user_level = purchase.user.level_at(purchase.purchased_at)
    my_level_at_purchase = advisor.level_at(purchase.purchased_at)
    
    product = item.product
    purchase_user_price = product.product_prices.find_by(level_id: purchase_user_level.id)&.price || 0
    my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
    
    if purchase_user_price > my_price
      diff = purchase_user_price - my_price
      item_bonus = diff * item.quantity
      descendant_bonus_total += item_bonus
      puts "  購入ID: #{purchase.id}, 購入者: #{purchase.user.display_name}, 商品: #{product.name}, 階層差額: #{diff}円, ボーナス: #{item_bonus}円"
    else
      puts "  購入ID: #{purchase.id}, 購入者: #{purchase.user.display_name}, 商品: #{product.name}, 階層差額なし"
    end
  end
else
  puts "子孫なし"
end

puts "子孫の販売ボーナス合計: #{descendant_bonus_total}円"

# 病院9の購入データを詳しく確認
puts "\n=== 病院9の購入データ詳細 ==="
if hospital9
  hospital9_purchases = hospital9.purchases.where(purchased_at: start_date..end_date)
  puts "病院9の8月の購入件数: #{hospital9_purchases.count}"
  
  hospital9_purchases.each do |purchase|
    puts "\n購入ID: #{purchase.id}, 購入日: #{purchase.purchased_at.strftime('%Y/%m/%d')}"
    purchase.purchase_items.each do |item|
      puts "  商品: #{item.product.name}, 数量: #{item.quantity}, 単価: #{item.unit_price}円"
      
      # この購入に対するアドバイザー5-1のインセンティブを計算
      hospital9_level = hospital9.level_at(purchase.purchased_at)
      advisor_level = advisor.level_at(purchase.purchased_at)
      
      hospital9_price = item.product.product_prices.find_by(level_id: hospital9_level.id)&.price || 0
      advisor_price = item.product.product_prices.find_by(level_id: advisor_level.id)&.price || 0
      
      puts "  病院9の購入時レベル: #{hospital9_level.name}, 価格: #{hospital9_price}円"
      puts "  アドバイザー5-1の購入時レベル: #{advisor_level.name}, 価格: #{advisor_price}円"
      
      if hospital9_price > advisor_price
        diff = hospital9_price - advisor_price
        incentive = diff * item.quantity
        puts "  階層差額: #{diff}円, インセンティブ: #{incentive}円"
      else
        puts "  階層差額なし"
      end
    end
  end
end

# (3) 無資格者の販売
puts "\n--- (3) 無資格者の販売 ---"
unqualified_referrals = advisor.referrals.reject(&:bonus_eligible?)
puts "無資格者数: #{unqualified_referrals.count}"

unqualified_bonus_total = 0

unqualified_referrals.each do |child|
  child_purchase_items = PurchaseItem.joins(:purchase)
                                    .where(purchases: { user_id: child.id, purchased_at: start_date..end_date })
                                    .includes(:product, purchase: :user)
  
  puts "#{child.display_name}の購入アイテム数: #{child_purchase_items.count}"
  
  child_purchase_items.each do |item|
    purchase_date = item.purchase.purchased_at
    my_level_at_purchase = advisor.level_at(purchase_date)
    product = item.product
    base_price = product.base_price
    my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
    diff = base_price - my_price
    
    if diff.positive?
      item_bonus = diff * item.quantity
      unqualified_bonus_total += item_bonus
      puts "  購入ID: #{item.purchase.id}, 商品: #{product.name}, ボーナス: #{item_bonus}円"
    end
  end
end

puts "無資格者販売ボーナス合計: #{unqualified_bonus_total}円"

# 合計
manual_total = my_bonus_total + descendant_bonus_total + unqualified_bonus_total
puts "\n=== 手動計算結果 ==="
puts "1. 自分の販売: #{my_bonus_total}円"
puts "2. 子孫の販売: #{descendant_bonus_total}円"
puts "3. 無資格者販売: #{unqualified_bonus_total}円"
puts "手動計算合計: #{manual_total}円"

# システム計算結果
system_total = advisor.bonus_in_period(start_date, end_date)
puts "\nシステム計算結果: #{system_total}円"
puts "差額: #{system_total - manual_total}円"

# 重複チェック
puts "\n=== 重複チェック ==="
my_purchase_ids = my_purchase_items.map { |item| item.purchase.id }.uniq
descendant_purchase_ids = descendant_purchase_items.map { |item| item.purchase.id }.uniq rescue []

puts "自分の購入ID: #{my_purchase_ids}"
puts "子孫の購入ID: #{descendant_purchase_ids}"

overlap = my_purchase_ids & descendant_purchase_ids
if overlap.any?
  puts "⚠️  重複している購入ID: #{overlap}"
  puts "これが重複計算の原因です！"
else
  puts "✅ 購入IDに重複はありません"
end

# 病院9が自分の子孫に含まれているかチェック
if hospital9
  puts "\n病院9がアドバイザー5-1の子孫に含まれているか: #{descendant_user_ids.include?(hospital9.id)}"
  puts "病院9がアドバイザー5-1の直接紹介者か: #{advisor.referrals.include?(hospital9)}"
end

# bonus_for_purchase_itemの詳細確認
puts "\n=== bonus_for_purchase_item の詳細確認 ==="
my_purchase_items.each do |item|
  puts "\n購入ID: #{item.purchase.id}, 商品: #{item.product.name}"
  
  purchase_date = item.purchase.purchased_at
  my_level_at_purchase = advisor.level_at(purchase_date)
  product = item.product
  base_price = product.base_price
  my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
  
  puts "  購入日: #{purchase_date}"
  puts "  購入時のレベル: #{my_level_at_purchase.name}"
  puts "  基本価格: #{base_price}円"
  puts "  自分の価格: #{my_price}円"
  puts "  単価差額: #{base_price - my_price}円"
  puts "  数量: #{item.quantity}"
  puts "  期待ボーナス: #{(base_price - my_price) * item.quantity}円"
  
  actual_bonus = advisor.bonus_for_purchase_item(item)
  puts "  実際のボーナス: #{actual_bonus}円"
end