# db/fixtures/products_price.rb
# Seed-Fu: ProductPrice 全リセット & 再投入（level_id:1=アジアビジネストラストは全商品0円）
# 何度実行しても安全（idempotent）

# 1) 全削除（高速・コールバック無）
ProductPrice.delete_all

# 2) レベルIDを名前から解決（環境差異に強い）
lv = %w[アジアビジネストラスト 特約代理店 代理店 アドバイザー サロン 病院 その他].map { |n|
  [n, Level.find_by!(name: n).id]
}.to_h

# 3) 商品ごとの価格マップ
#   - Product(1): base 50,000
#   - Product(2..4): base 30,000
#   - Product(5): base 3,800,000
price_map_by_product = {
  1 => { lv["アジアビジネストラスト"] => 0, lv["特約代理店"] => 36_000, lv["代理店"] => 38_000, lv["アドバイザー"] => 40_000, lv["サロン"] => 50_000, lv["病院"] => 50_000, lv["その他"] => 50_000 },
  2 => { lv["アジアビジネストラスト"] => 0, lv["特約代理店"] => 20_000, lv["代理店"] => 22_000, lv["アドバイザー"] => 24_000, lv["サロン"] => 30_000, lv["病院"] => 30_000, lv["その他"] => 30_000 },
  3 => { lv["アジアビジネストラスト"] => 0, lv["特約代理店"] => 20_000, lv["代理店"] => 22_000, lv["アドバイザー"] => 24_000, lv["サロン"] => 30_000, lv["病院"] => 30_000, lv["その他"] => 30_000 },
  4 => { lv["アジアビジネストラスト"] => 0, lv["特約代理店"] => 20_000, lv["代理店"] => 22_000, lv["アドバイザー"] => 24_000, lv["サロン"] => 30_000, lv["病院"] => 30_000, lv["その他"] => 30_000 },
  5 => { lv["アジアビジネストラスト"] => 0, lv["特約代理店"] => 3_500_000, lv["代理店"] => 3_550_000, lv["アドバイザー"] => 3_600_000, lv["サロン"] => 3_800_000, lv["病院"] => 3_800_000, lv["その他"] => 3_800_000 }
}

# 4) 存在する Product のみに投入（抜けても安全）
existing_pids = Product.where(id: price_map_by_product.keys).pluck(:id)

existing_pids.each do |pid|
  price_map_by_product[pid].each do |level_id, price|
    ProductPrice.seed(:product_id, :level_id) do |pp|
      pp.product_id = pid
      pp.level_id   = level_id
      pp.price      = price
    end
  end
end

puts "✅ ProductPrice seeded: #{ProductPrice.count} rows (products=#{existing_pids.size})"
