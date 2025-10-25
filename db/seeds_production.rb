# 本番環境用シードファイル
# 既存データを保護しながら新しいWOTT関連データのみを追加

puts "🔄 Production seeding started..."

# WottLevelデータを作成（既存データがない場合のみ）
if WottLevel.count == 0
  wott_level_data = [
    { id: 1, name: "アジアビジネストラスト", value: 0 },
    { id: 2, name: "総代理店", value: 1 },
    { id: 3, name: "代理店", value: 2 },
    { id: 4, name: "サポーター", value: 3 },
    { id: 5, name: "サロン", value: 4 },
    { id: 6, name: "クリニック", value: 5 },
    { id: 7, name: "お客様", value: 6 }
  ]

  wott_level_data.each do |data|
    WottLevel.find_or_create_by(id: data[:id]) do |wl|
      wl.name = data[:name]
      wl.value = data[:value]
    end
  end
  
  puts "✅ Created WOTT levels"
else
  puts "ℹ️  WOTT levels already exist, skipping creation"
end

# WOTT商品の価格設定（商品ID 6がWOTT Deviceの場合）
wott_product = Product.find_by(id: 6)
if wott_product && wott_product.respond_to?(:category) && wott_product.category == 'wott'
  wott_levels = WottLevel.all.index_by(&:name)
  
  wott_price_data = [
    { wott_level_name: "アジアビジネストラスト", price: 500000 },
    { wott_level_name: "総代理店", price: 880000 },
    { wott_level_name: "代理店", price: 990000 },
    { wott_level_name: "サポーター", price: 1045000 },
    { wott_level_name: "サロン", price: 1100000 },
    { wott_level_name: "クリニック", price: 1100000 },
    { wott_level_name: "お客様", price: 1100000 }
  ]
  
  wott_price_data.each do |data|
    wott_level = wott_levels[data[:wott_level_name]]
    if wott_level
      ProductPrice.find_or_create_by(product: wott_product, wott_level: wott_level) do |pp|
        pp.price = data[:price]
      end
    end
  end
  
  puts "✅ Created WOTT product pricing structure"
else
  puts "ℹ️  WOTT product not found or not configured, skipping price setup"
end

puts "✅ Production seeding completed!"