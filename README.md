user = User.find(19)
selected_month_start = Date.new(2025, 8, 1)
selected_month_end = Date.new(2025, 8, 31)

# 自分の購入
my_purchases = user.purchases.where(purchased_at: selected_month_start..selected_month_end)
puts "=== 自分の購入 ==="
my_purchases.each do |purchase|
  puts "購入#{purchase.id}: 販売者=#{purchase.user.name}, 購入日=#{purchase.purchased_at}"
end

# 自分+子孫の購入
descendant_ids = user.descendants.pluck(:id)
all_purchases = Purchase.where(user_id: [user.id] + descendant_ids)
                       .where(purchased_at: selected_month_start..selected_month_end)
puts "=== 自分+子孫の購入 ==="
all_purchases.each do |purchase|
  puts "購入#{purchase.id}: 販売者=#{purchase.user.name}, 購入日=#{purchase.purchased_at}"
end

puts "自分の購入数: #{my_purchases.count}"
puts "全体の購入数: #{all_purchases.count}"
puts "子孫のID: #{descendant_ids}"



