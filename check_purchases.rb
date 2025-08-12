# 8月の購入データを詳細確認

puts "=== 8月の購入データ確認 ==="

# 8月の期間
start_date = Date.new(2025, 8, 1)
end_date = Date.new(2025, 8, 31)

# 8月の全購入を取得
august_purchases = Purchase.includes(:user, purchase_items: :product)
                          .where(purchased_at: start_date.beginning_of_day..end_date.end_of_day)
                          .order(:purchased_at)

puts "8月の総購入件数: #{august_purchases.count}"

august_purchases.each do |purchase|
  puts "\n--- 購入 ID: #{purchase.id} ---"
  puts "購入者: #{purchase.user.display_name} (ID: #{purchase.user.id})"
  puts "購入日: #{purchase.purchased_at.strftime('%Y/%m/%d %H:%M')}"
  puts "病院: #{purchase.hospital&.name || 'N/A'}"
  
  purchase.purchase_items.each do |item|
    puts "  商品: #{item.product.name}"
    puts "  数量: #{item.quantity}"
    puts "  単価: #{item.unit_price}円"
    puts "  販売店価格: #{item.seller_price}円"
    puts "  合計: #{item.total_price}円"
  end
  
  puts "購入合計: #{purchase.total_amount}円"
end

# アドバイザー5-1関連の購入のみ
advisor = User.find_by(id: 5)
if advisor
  puts "\n=== アドバイザー5-1関連の購入 ==="
  
  # 自分の購入
  my_purchases = advisor.purchases.where(purchased_at: start_date.beginning_of_day..end_date.end_of_day)
  puts "自分の購入: #{my_purchases.count}件"
  
  # 子孫の購入
  descendant_purchases = Purchase.where(user_id: advisor.descendant_ids)
                                .where(purchased_at: start_date.beginning_of_day..end_date.end_of_day)
  puts "子孫の購入: #{descendant_purchases.count}件"
  
  # 重複チェック
  all_related_purchases = (my_purchases.to_a + descendant_purchases.to_a).uniq
  puts "重複除去後: #{all_related_purchases.count}件"
  
  if my_purchases.count + descendant_purchases.count != all_related_purchases.count
    puts "⚠️  重複があります！"
    
    # 重複している購入を特定
    my_ids = my_purchases.pluck(:id)
    descendant_ids = descendant_purchases.pluck(:id)
    duplicate_ids = my_ids & descendant_ids
    
    puts "重複している購入ID: #{duplicate_ids}"
  end
end