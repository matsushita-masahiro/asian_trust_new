#!/usr/bin/env ruby
require_relative 'config/environment'

# 中村結衣さんの10月全体のインセンティブ計算
user = User.find(11)

# 10月全体の範囲を指定
start_date = Date.new(2025, 10, 1)
end_date = Date.new(2025, 10, 31)

service = IncentiveCalculationService.new(user, start_date, end_date)
result = service.calculate_detailed_incentives

puts "=== #{user.display_name}さんの10月全体のインセンティブ計算 ==="
puts "計算期間: #{start_date} 〜 #{end_date}"
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

# 購入詳細を確認（最初の10件のみ）
puts "=== 購入詳細（最初の10件） ==="
result[:details][:purchase_details].first(10).each_with_index do |detail, index|
  puts "#{index + 1}. #{detail[:purchaser_name]} - #{detail[:product_name]}"
  puts "   購入日: #{detail[:purchase_date]}"
  puts "   数量: #{detail[:quantity]}, 単価: ¥#{detail[:unit_price]}"
  puts "   インセンティブ単価: ¥#{detail[:incentive_unit_price]}"
  puts "   合計インセンティブ: ¥#{detail[:total_incentive]}"
  puts "   計算式: #{detail[:calculation_details][:calculation_formula]}"
  puts
end

if result[:details][:purchase_details].length > 10
  puts "... 他 #{result[:details][:purchase_details].length - 10} 件"
end