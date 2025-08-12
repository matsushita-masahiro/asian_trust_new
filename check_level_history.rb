# アドバイザー5-1のレベル履歴を確認

puts "=== アドバイザー5-1 レベル履歴確認 ==="

# アドバイザー5-1を取得
advisor = User.find_by(id: 5)
if advisor.nil?
  puts "アドバイザー5-1が見つかりません"
  exit
end

puts "ユーザー: #{advisor.display_name} (ID: #{advisor.id})"
puts "現在のレベル: #{advisor.level&.name} (ID: #{advisor.level_id})"

# レベル履歴を確認
puts "\n=== レベル履歴 ==="
histories = advisor.user_level_histories.by_effective_date
puts "履歴件数: #{histories.count}"

if histories.empty?
  puts "⚠️  レベル履歴が存在しません！"
  puts "履歴を作成する必要があります。"
else
  histories.each_with_index do |history, index|
    puts "\n--- 履歴 #{index + 1} ---"
    puts "レベル: #{history.level.name} (ID: #{history.level_id})"
    puts "有効開始: #{history.effective_from}"
    puts "有効終了: #{history.effective_to || '現在まで'}"
    puts "変更理由: #{history.change_reason}"
    puts "変更者: #{history.changed_by&.display_name || 'N/A'}"
  end
end

# 8月の特定日でのレベルを確認
puts "\n=== 8月の特定日でのレベル確認 ==="

test_dates = [
  Date.new(2025, 8, 7),   # 8/7の購入日
  Date.new(2025, 8, 16)   # 8/16の購入日
]

test_dates.each do |date|
  level_at_date = advisor.level_at(date)
  puts "#{date.strftime('%Y/%m/%d')}時点のレベル: #{level_at_date.name} (ID: #{level_at_date.id})"
end

# 8月の購入データと期待されるインセンティブを確認
puts "\n=== 8月の購入データとインセンティブ確認 ==="

august_purchases = advisor.purchases.includes(purchase_items: :product)
                          .where(purchased_at: Date.new(2025, 8, 1).beginning_of_day..Date.new(2025, 8, 31).end_of_day)

august_purchases.each do |purchase|
  puts "\n--- 購入 #{purchase.id} ---"
  puts "購入日: #{purchase.purchased_at.strftime('%Y/%m/%d')}"
  puts "購入時点のレベル: #{advisor.level_at(purchase.purchased_at).name}"
  
  purchase.purchase_items.each do |item|
    product = item.product
    purchase_level = advisor.level_at(purchase.purchased_at)
    my_price = product.product_prices.find_by(level_id: purchase_level.id)&.price || 0
    base_price = product.base_price
    
    expected_incentive = (base_price - my_price) * item.quantity
    
    puts "  商品: #{product.name}"
    puts "  数量: #{item.quantity}"
    puts "  基本価格: #{base_price}円"
    puts "  購入時点での自分の価格: #{my_price}円"
    puts "  期待インセンティブ: #{expected_incentive}円"
  end
end

# 現在のシステム計算結果
puts "\n=== 現在のシステム計算結果 ==="
system_bonus = advisor.bonus_in_month("2025-08")
puts "システム計算結果: #{system_bonus}円"

# 期待値との比較
expected_total = 300000 + 360000  # 8/7: 300000円 + 8/16: 360000円
puts "期待値: #{expected_total}円"
puts "差額: #{system_bonus - expected_total}円"