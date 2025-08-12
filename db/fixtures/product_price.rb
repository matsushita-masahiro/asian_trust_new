# ProductPrice fixtures
# 商品とレベルごとの価格設定

# 既存データをクリア
ProductPrice.destroy_all

# レベル0（特別レベル）は全商品で0円に設定

# 商品1: 骨髄幹細胞培培養上清液 (base_price: 50000)
product_1_prices = []
[0, 1, 2, 3, 4, 5, 6, 7].each_with_index do |level_id, index|
  price = case level_id
          when 0 then 0      # 特別レベル（無料）
          when 1 then 0      # 特約代理店（無料）
          when 2 then 36000  # 特約代理店
          when 3 then 38000  # 代理店
          when 4 then 40000  # アドバイザー
          when 5 then 50000  # サロン
          when 6 then 50000  # 病院
          when 7 then 50000  # その他
          end
  
  product_1_prices << { id: index + 1, product_id: 1, level_id: level_id, price: price }
end

ProductPrice.seed(:id, *product_1_prices)

# 商品2: テスト商品2 (base_price: 30000)
product_2_prices = []
[0, 2, 3, 4, 5, 6, 7].each_with_index do |level_id, index|
  price = case level_id
          when 0 then 0      # 特別レベル（無料）
          when 2 then 20000  # 特約代理店
          when 3 then 22000  # 代理店
          when 4 then 24000  # アドバイザー
          when 5 then 30000  # サロン
          when 6 then 30000  # 病院
          when 7 then 30000  # その他
          end
  
  product_2_prices << { id: index + 9, product_id: 2, level_id: level_id, price: price }
end

ProductPrice.seed(:id, *product_2_prices)

# 商品3: テスト商品3 (base_price: 30000)
product_3_prices = []
[0, 2, 3, 4, 5, 6, 7].each_with_index do |level_id, index|
  price = case level_id
          when 0 then 0      # 特別レベル（無料）
          when 2 then 20000  # 特約代理店
          when 3 then 22000  # 代理店
          when 4 then 24000  # アドバイザー
          when 5 then 30000  # サロン
          when 6 then 30000  # 病院
          when 7 then 30000  # その他
          end
  
  product_3_prices << { id: index + 16, product_id: 3, level_id: level_id, price: price }
end

ProductPrice.seed(:id, *product_3_prices)

# 商品4: テスト商品4 (base_price: 30000)
product_4_prices = []
[0, 2, 3, 4, 5, 6, 7].each_with_index do |level_id, index|
  price = case level_id
          when 0 then 0      # 特別レベル（無料）
          when 2 then 20000  # 特約代理店
          when 3 then 22000  # 代理店
          when 4 then 24000  # アドバイザー
          when 5 then 30000  # サロン
          when 6 then 30000  # 病院
          when 7 then 30000  # その他
          end
  
  product_4_prices << { id: index + 23, product_id: 4, level_id: level_id, price: price }
end

ProductPrice.seed(:id, *product_4_prices)

# 商品5: 高額商品テスト (base_price: 4000000)
product_5_prices = []
[0, 2, 3, 4, 5, 6, 7].each_with_index do |level_id, index|
  price = case level_id
          when 0 then 0        # 特別レベル（無料）
          when 2 then 3500000  # 特約代理店
          when 3 then 3550000  # 代理店
          when 4 then 3600000  # アドバイザー
          when 5 then 3800000  # サロン
          when 6 then 3800000  # 病院
          when 7 then 3800000  # その他
          end
  
  product_5_prices << { id: index + 30, product_id: 5, level_id: level_id, price: price }
end

ProductPrice.seed(:id, *product_5_prices)

puts "ProductPrice fixtures loaded: #{ProductPrice.count} records"