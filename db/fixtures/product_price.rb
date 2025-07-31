# ProductPrice fixtures
# 商品とレベルごとの価格設定

# 既存データをクリア
ProductPrice.destroy_all

# 商品1: 骨髄幹細胞培培養上清液 (base_price: 50000)
ProductPrice.seed(:id,
  { id: 1, product_id: 1, level_id: 2, price: 36000 },   # 特約代理店
  { id: 2, product_id: 1, level_id: 3, price: 38000 },   # 代理店
  { id: 3, product_id: 1, level_id: 4, price: 40000 },   # アドバイザー
  { id: 4, product_id: 1, level_id: 5, price: 50000 },   # サロン
  { id: 5, product_id: 1, level_id: 6, price: 50000 },   # 病院
  { id: 6, product_id: 1, level_id: 7, price: 50000 }    # その他
)

# 商品2: テスト商品2 (base_price: 30000)
ProductPrice.seed(:id,
  { id: 7, product_id: 2, level_id: 2, price: 20000 },   # 特約代理店
  { id: 8, product_id: 2, level_id: 3, price: 22000 },   # 代理店
  { id: 9, product_id: 2, level_id: 4, price: 24000 },   # アドバイザー
  { id: 10, product_id: 2, level_id: 5, price: 30000 },  # サロン
  { id: 11, product_id: 2, level_id: 6, price: 30000 },  # 病院
  { id: 12, product_id: 2, level_id: 7, price: 30000 }   # その他
)

# 商品3: テスト商品3 (base_price: 30000)
ProductPrice.seed(:id,
  { id: 13, product_id: 3, level_id: 2, price: 20000 },  # 特約代理店
  { id: 14, product_id: 3, level_id: 3, price: 22000 },  # 代理店
  { id: 15, product_id: 3, level_id: 4, price: 24000 },  # アドバイザー
  { id: 16, product_id: 3, level_id: 5, price: 30000 },  # サロン
  { id: 17, product_id: 3, level_id: 6, price: 30000 },  # 病院
  { id: 18, product_id: 3, level_id: 7, price: 30000 }   # その他
)

# 商品4: テスト商品4 (base_price: 30000)
ProductPrice.seed(:id,
  { id: 19, product_id: 4, level_id: 2, price: 20000 },  # 特約代理店
  { id: 20, product_id: 4, level_id: 3, price: 22000 },  # 代理店
  { id: 21, product_id: 4, level_id: 4, price: 24000 },  # アドバイザー
  { id: 22, product_id: 4, level_id: 5, price: 30000 },  # サロン
  { id: 23, product_id: 4, level_id: 6, price: 30000 },  # 病院
  { id: 24, product_id: 4, level_id: 7, price: 30000 }   # その他
)

# 商品5: 高額商品テスト (base_price: 4000000)
ProductPrice.seed(:id,
  { id: 25, product_id: 5, level_id: 2, price: 3500000 }, # 特約代理店
  { id: 26, product_id: 5, level_id: 3, price: 3550000 }, # 代理店
  { id: 27, product_id: 5, level_id: 4, price: 3600000 }, # アドバイザー
  { id: 28, product_id: 5, level_id: 5, price: 3800000 }, # サロン
  { id: 29, product_id: 5, level_id: 6, price: 3800000 }, # 病院
  { id: 30, product_id: 5, level_id: 7, price: 3800000 }  # その他
)

puts "ProductPrice fixtures loaded: #{ProductPrice.count} records"