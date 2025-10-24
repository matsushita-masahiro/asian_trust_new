# db/fixtures/products_price.rb
# Seed-Fu: ProductPrice 全リセット & 再投入（level_id:1=アジアビジネストラストは全商品0円）
# 何度実行しても安全（idempotent）

# 1) 全削除（高速・コールバック無）& IDシーケンスリセット
ProductPrice.delete_all
# SQLiteの場合はシーケンステーブルを直接更新
if ActiveRecord::Base.connection.adapter_name == 'SQLite'
  ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='product_prices'")
end

# 2) レベルIDを明示的に指定（ID採番と一致）
lv = {
  "アジアビジネストラスト" => 1,
  "総代理店" => 2,
  "代理店" => 3,
  "アドバイザー" => 4,
  "サロン" => 5,
  "クリニック" => 6,
  "サポーター" => 7,
  "お客様" => 8
}

# 3) 商品ごとの価格マップ
#   - Product(1): base 50,000
#   - Product(2..4): base 30,000
#   - Product(5): base 3,800,000
price_map_by_product = {
  1 => { lv["アジアビジネストラスト"] => 4000, lv["総代理店"] => 26_000, lv["代理店"] => 28_000, lv["アドバイザー"] => 30_000, lv["サロン"] => 40_000, lv["クリニック"] => 40_000, lv["サポーター"] => 36_000, lv["お客様"] => 40_000 },
  2 => { lv["アジアビジネストラスト"] => 6000, lv["総代理店"] => 20_000, lv["代理店"] => 22_000, lv["アドバイザー"] => 24_000, lv["サロン"] => 30_000, lv["クリニック"] => 30_000, lv["サポーター"] => 30_000, lv["お客様"] => 30_000 },
  3 => { lv["アジアビジネストラスト"] => 6000, lv["総代理店"] => 20_000, lv["代理店"] => 22_000, lv["アドバイザー"] => 24_000, lv["サロン"] => 30_000, lv["クリニック"] => 30_000, lv["サポーター"] => 30_000, lv["お客様"] => 30_000 },
  4 => { lv["アジアビジネストラスト"] => 6000, lv["総代理店"] => 20_000, lv["代理店"] => 22_000, lv["アドバイザー"] => 24_000, lv["サロン"] => 30_000, lv["クリニック"] => 30_000, lv["サポーター"] => 30_000, lv["お客様"] => 30_000 },
  5 => { lv["アジアビジネストラスト"] => 400000, lv["総代理店"] => 3_500_000, lv["代理店"] => 3_550_000, lv["アドバイザー"] => 3_600_000, lv["サロン"] => 3_800_000, lv["クリニック"] => 3_800_000, lv["サポーター"] => 3_800_000, lv["お客様"] => 3_800_000 }
}

# 4) 存在する Product のみに投入（抜けても安全）& IDを明示的に指定
existing_pids = Product.where(id: price_map_by_product.keys).pluck(:id)

id_counter = 1
existing_pids.each do |pid|
  price_map_by_product[pid].each do |level_id, price|
    ProductPrice.seed(:id) do |pp|
      pp.id = id_counter
      pp.product_id = pid
      pp.level_id   = level_id
      pp.price      = price
    end
    id_counter += 1
  end
end

puts "✅ ProductPrice seeded: #{ProductPrice.count} rows (products=#{existing_pids.size})"
