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
#   - Product(7-8): MANNERSSOUND I-II base 143,000 (税込)
#   - Product(9-14): MANNERSSOUND III-VIII base 121,000 (税込)
price_map_by_product = {
  1 => { lv["アジアビジネストラスト"] => 4000, lv["総代理店"] => 26_000, lv["代理店"] => 28_000, lv["アドバイザー"] => 30_000, lv["サロン"] => 40_000, lv["クリニック"] => 40_000, lv["サポーター"] => 36_000, lv["お客様"] => 40_000 },
  2 => { lv["アジアビジネストラスト"] => 6000, lv["総代理店"] => 20_000, lv["代理店"] => 22_000, lv["アドバイザー"] => 24_000, lv["サロン"] => 30_000, lv["クリニック"] => 30_000, lv["サポーター"] => 30_000, lv["お客様"] => 30_000 },
  3 => { lv["アジアビジネストラスト"] => 6000, lv["総代理店"] => 20_000, lv["代理店"] => 22_000, lv["アドバイザー"] => 24_000, lv["サロン"] => 30_000, lv["クリニック"] => 30_000, lv["サポーター"] => 30_000, lv["お客様"] => 30_000 },
  4 => { lv["アジアビジネストラスト"] => 6000, lv["総代理店"] => 20_000, lv["代理店"] => 22_000, lv["アドバイザー"] => 24_000, lv["サロン"] => 30_000, lv["クリニック"] => 30_000, lv["サポーター"] => 30_000, lv["お客様"] => 30_000 },
  5 => { lv["アジアビジネストラスト"] => 400000, lv["総代理店"] => 3_500_000, lv["代理店"] => 3_550_000, lv["アドバイザー"] => 3_600_000, lv["サロン"] => 3_800_000, lv["クリニック"] => 3_800_000, lv["サポーター"] => 3_800_000, lv["お客様"] => 3_800_000 },

  # MANNERSSOUND商品 (税込価格・インセンティブ率で管理)
  7 => { lv["アジアビジネストラスト"] => { price: 143_000, rate: 0 }, lv["総代理店"] => { price: 143_000, rate: 20 }, lv["代理店"] => { price: 143_000, rate: 15 }, lv["アドバイザー"] => { price: 143_000, rate: 10 }, lv["サロン"] => { price: 143_000, rate: 0 }, lv["クリニック"] => { price: 143_000, rate: 0 }, lv["サポーター"] => { price: 143_000, rate: 5 }, lv["お客様"] => { price: 143_000, rate: 0 } },
  8 => { lv["アジアビジネストラスト"] => { price: 143_000, rate: 0 }, lv["総代理店"] => { price: 143_000, rate: 20 }, lv["代理店"] => { price: 143_000, rate: 15 }, lv["アドバイザー"] => { price: 143_000, rate: 10 }, lv["サロン"] => { price: 143_000, rate: 0 }, lv["クリニック"] => { price: 143_000, rate: 0 }, lv["サポーター"] => { price: 143_000, rate: 5 }, lv["お客様"] => { price: 143_000, rate: 0 } },
  9 => { lv["アジアビジネストラスト"] => { price: 121_000, rate: 0 }, lv["総代理店"] => { price: 121_000, rate: 20 }, lv["代理店"] => { price: 121_000, rate: 15 }, lv["アドバイザー"] => { price: 121_000, rate: 10 }, lv["サロン"] => { price: 121_000, rate: 0 }, lv["クリニック"] => { price: 121_000, rate: 0 }, lv["サポーター"] => { price: 121_000, rate: 5 }, lv["お客様"] => { price: 121_000, rate: 0 } },
  10 => { lv["アジアビジネストラスト"] => { price: 121_000, rate: 0 }, lv["総代理店"] => { price: 121_000, rate: 20 }, lv["代理店"] => { price: 121_000, rate: 15 }, lv["アドバイザー"] => { price: 121_000, rate: 10 }, lv["サロン"] => { price: 121_000, rate: 0 }, lv["クリニック"] => { price: 121_000, rate: 0 }, lv["サポーター"] => { price: 121_000, rate: 5 }, lv["お客様"] => { price: 121_000, rate: 0 } },
  11 => { lv["アジアビジネストラスト"] => { price: 121_000, rate: 0 }, lv["総代理店"] => { price: 121_000, rate: 20 }, lv["代理店"] => { price: 121_000, rate: 15 }, lv["アドバイザー"] => { price: 121_000, rate: 10 }, lv["サロン"] => { price: 121_000, rate: 0 }, lv["クリニック"] => { price: 121_000, rate: 0 }, lv["サポーター"] => { price: 121_000, rate: 5 }, lv["お客様"] => { price: 121_000, rate: 0 } },
  12 => { lv["アジアビジネストラスト"] => { price: 121_000, rate: 0 }, lv["総代理店"] => { price: 121_000, rate: 20 }, lv["代理店"] => { price: 121_000, rate: 15 }, lv["アドバイザー"] => { price: 121_000, rate: 10 }, lv["サロン"] => { price: 121_000, rate: 0 }, lv["クリニック"] => { price: 121_000, rate: 0 }, lv["サポーター"] => { price: 121_000, rate: 5 }, lv["お客様"] => { price: 121_000, rate: 0 } },
  13 => { lv["アジアビジネストラスト"] => { price: 121_000, rate: 0 }, lv["総代理店"] => { price: 121_000, rate: 20 }, lv["代理店"] => { price: 121_000, rate: 15 }, lv["アドバイザー"] => { price: 121_000, rate: 10 }, lv["サロン"] => { price: 121_000, rate: 0 }, lv["クリニック"] => { price: 121_000, rate: 0 }, lv["サポーター"] => { price: 121_000, rate: 5 }, lv["お客様"] => { price: 121_000, rate: 0 } },
  14 => { lv["アジアビジネストラスト"] => { price: 121_000, rate: 0 }, lv["総代理店"] => { price: 121_000, rate: 20 }, lv["代理店"] => { price: 121_000, rate: 15 }, lv["アドバイザー"] => { price: 121_000, rate: 10 }, lv["サロン"] => { price: 121_000, rate: 0 }, lv["クリニック"] => { price: 121_000, rate: 0 }, lv["サポーター"] => { price: 121_000, rate: 5 }, lv["お客様"] => { price: 121_000, rate: 0 } },
  # エアガン商品 (税込価格・インセンティブ率で管理)
  15 => { lv["アジアビジネストラスト"] => { price: 600_000, rate: 0 }, lv["総代理店"] => { price: 600_000, rate: 20 }, lv["代理店"] => { price: 600_000, rate: 15 }, lv["アドバイザー"] => { price: 600_000, rate: 10 }, lv["サロン"] => { price: 600_000, rate: 0 }, lv["クリニック"] => { price: 600_000, rate: 0 }, lv["サポーター"] => { price: 600_000, rate: 5 }, lv["お客様"] => { price: 600_000, rate: 0 } }
}

# 4) 存在する Product のみに投入（抜けても安全）& IDを明示的に指定
existing_pids = Product.where(id: price_map_by_product.keys).pluck(:id)

id_counter = 1
existing_pids.each do |pid|
  price_map_by_product[pid].each do |level_id, price_data|
    ProductPrice.seed(:id) do |pp|
      pp.id = id_counter
      pp.product_id = pid
      pp.level_id   = level_id
      
      # price_dataがハッシュの場合（MANNERSSOUND/エアガン）とそうでない場合（従来商品）を判定
      if price_data.is_a?(Hash)
        pp.price = price_data[:price]
        # rateを小数値に変換（20 -> 0.2）
        pp.incentive_rate = price_data[:rate] > 0 ? price_data[:rate] / 100.0 : nil
      else
        pp.price = price_data
        pp.incentive_rate = nil
      end
    end
    id_counter += 1
  end
end

# WOTT商品専用の処理（WottLevelを使用）
wott_product_id = 6
if Product.exists?(wott_product_id)
  wott_level_map = {
    1 => { rate: 0 },   # アジアビジネストラスト
    2 => { rate: 20 },  # 総代理店
    3 => { rate: 10 },  # 代理店
    4 => { rate: 5 },   # サポーター
    5 => { rate: 0 },   # サロン
    6 => { rate: 0 },   # クリニック
    7 => { rate: 0 }    # お客様
  }
  
  wott_level_map.each do |wott_level_id, data|
    ProductPrice.seed(:id) do |pp|
      pp.id = id_counter
      pp.product_id = wott_product_id
      pp.wott_level_id = wott_level_id
      pp.price = 1_100_000
      pp.incentive_rate = data[:rate] > 0 ? data[:rate] / 100.0 : nil
    end
    id_counter += 1
  end
end

puts "✅ ProductPrice seeded: #{ProductPrice.count} rows (products=#{existing_pids.size + (Product.exists?(wott_product_id) ? 1 : 0)})"
