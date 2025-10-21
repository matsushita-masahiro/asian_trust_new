#!/usr/bin/env ruby
require_relative 'config/environment'

# 経路の順序を確認
suzuki = User.find_by(name: "鈴木愛美")
nakamura = User.find_by(name: "中村結衣")
yoshida = User.find_by(name: "吉田博文")

puts "=== 経路の順序確認 ==="
puts "鈴木愛美: #{suzuki.display_name} (ID: #{suzuki.id})"
puts "中村結衣: #{nakamura.display_name} (ID: #{nakamura.id})"
puts "吉田博文: #{yoshida.display_name} (ID: #{yoshida.id})"
puts

# 吉田博文から鈴木愛美への経路
path = yoshida.path_to_ancestor(suzuki)
puts "吉田博文 -> 鈴木愛美の経路:"
if path
  path.each_with_index do |user, index|
    puts "  #{index}: #{user.display_name} (ID: #{user.id}, Level: #{user.level&.name})"
  end
  puts "  経路の長さ: #{path.length}"
  
  # 中間の経路を確認
  if path.length > 2
    intermediate_path = path[1..-2]
    puts "  中間の経路:"
    intermediate_path.each_with_index do |user, index|
      puts "    #{index}: #{user.display_name} (受給資格: #{user.bonus_eligible?})"
    end
    
    # 逆順で受給資格者を探す
    eligible_user = intermediate_path.reverse.find(&:bonus_eligible?)
    puts "  見つかった受給資格者: #{eligible_user ? eligible_user.display_name : 'なし'}"
  end
else
  puts "  経路なし"
end
puts

# 価格を確認
product = Product.first
puts "=== 価格確認 ==="
puts "商品: #{product.name}"
puts "基本価格: ¥#{product.base_price}"

[suzuki, nakamura, yoshida].each do |user|
  price = product.product_prices.find_by(level_id: user.level.id)&.price || 0
  puts "#{user.display_name} (#{user.level&.name}): ¥#{price}"
end
puts

# 正しい計算
puts "=== 正しい計算 ==="
suzuki_price = product.product_prices.find_by(level_id: suzuki.level.id)&.price || 0
nakamura_price = product.product_prices.find_by(level_id: nakamura.level.id)&.price || 0
yoshida_price = product.product_prices.find_by(level_id: yoshida.level.id)&.price || 0

puts "吉田博文の購入に対する鈴木愛美さんのインセンティブ:"
puts "中村結衣の価格¥#{nakamura_price} - 鈴木愛美の価格¥#{suzuki_price} = ¥#{nakamura_price - suzuki_price}"