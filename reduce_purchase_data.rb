#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== 現在のPurchaseデータ状況 ==="

# 現在のPurchase件数
total_purchases = Purchase.count
total_items = PurchaseItem.count

puts "総Purchase件数: #{total_purchases}"
puts "総PurchaseItem件数: #{total_items}"
puts

# ユーザー別の購入件数を確認
user_purchases = Purchase.joins(:user)
                        .group('users.name')
                        .count
                        .sort_by { |name, count| -count }

puts "=== ユーザー別購入件数 ===\n"
user_purchases.each do |name, count|
  puts "#{name}: #{count}件"
end
puts

# 月別の購入件数を確認
monthly_purchases = Purchase.group("DATE_FORMAT(purchased_at, '%Y-%m')")
                           .count
                           .sort

puts "=== 月別購入件数 ==="
monthly_purchases.each do |month, count|
  puts "#{month}: #{count}件"
end
puts

# 削除戦略を提案
puts "=== 削除戦略 ==="
puts "目標: 20件程度に削減"
puts "現在: #{total_purchases}件"
puts "削除予定: #{total_purchases - 20}件"
puts

# 重複データを確認（同じユーザーの同じ日の購入）
duplicate_purchases = Purchase.select('user_id, DATE(purchased_at) as purchase_date, COUNT(*) as count')
                             .group('user_id, DATE(purchased_at)')
                             .having('COUNT(*) > 1')
                             .order('count DESC')

puts "=== 重複購入データ（同じユーザーの同じ日） ==="
duplicate_purchases.each do |dup|
  user = User.find(dup.user_id)
  puts "#{user.name}: #{dup.purchase_date} - #{dup.count}件"
end
puts

# 削除実行の確認
puts "削除を実行しますか？ (y/N)"
puts "1. 重複データを削除（同じユーザーの同じ日の購入を1件に統合）"
puts "2. 古いデータを削除（8月、9月のデータを削除）"
puts "3. 一部ユーザーのデータを削除"

response = gets.chomp.downcase

if response == 'y'
  puts "\n=== 削除実行 ==="
  
  # 1. 重複データの削除（同じユーザーの同じ日の購入で2件目以降を削除）
  deleted_count = 0
  
  duplicate_purchases.each do |dup|
    same_day_purchases = Purchase.where(user_id: dup.user_id)
                                .where('DATE(purchased_at) = ?', dup.purchase_date)
                                .order(:id)
    
    # 最初の1件を残して削除
    purchases_to_delete = same_day_purchases.offset(1)
    purchases_to_delete.each do |purchase|
      puts "削除: #{User.find(dup.user_id).name} - #{dup.purchase_date} (ID: #{purchase.id})"
      purchase.destroy
      deleted_count += 1
    end
  end
  
  puts "重複データ削除完了: #{deleted_count}件"
  
  # 2. 8月、9月のデータを削除
  old_purchases = Purchase.where('purchased_at < ?', Date.new(2025, 10, 1))
  old_count = old_purchases.count
  
  if old_count > 0
    puts "8月、9月のデータを削除: #{old_count}件"
    old_purchases.destroy_all
  end
  
  # 3. 残りが20件を超える場合、さらに削除
  remaining_count = Purchase.count
  puts "残り件数: #{remaining_count}件"
  
  if remaining_count > 20
    excess_count = remaining_count - 20
    excess_purchases = Purchase.order(:id).limit(excess_count)
    puts "追加削除: #{excess_count}件"
    excess_purchases.destroy_all
  end
  
  # 最終結果
  final_count = Purchase.count
  final_items = PurchaseItem.count
  
  puts "\n=== 削除完了 ==="
  puts "最終Purchase件数: #{final_count}"
  puts "最終PurchaseItem件数: #{final_items}"
  
else
  puts "削除をキャンセルしました"
end