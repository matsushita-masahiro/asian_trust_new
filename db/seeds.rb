puts "🔄 Seeding started......"

# Load fixtures
require 'seed-fu'

adapter = ActiveRecord::Base.connection.adapter_name

# データを適切な順序で削除（外部キー制約を考慮）
puts "🗑️ Cleaning existing data..."

# 外部キー制約を一時的に無効化（SQLiteの場合）
if adapter == "SQLite"
  ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF")
end

# 1. 購入請求書関連データを削除
PurchaseInvoice.delete_all

# 2. 購入関連データを削除
PurchaseItem.delete_all
Purchase.delete_all

# 3. 請求書関連データを削除
Invoice.delete_all

# 4. レベル変更申請を削除
LevelChangeApplication.delete_all

# 5. 紹介招待を削除
ReferralInvitation.delete_all

# 6. ユーザーレベル履歴を削除
UserLevelHistory.delete_all

# 7. カート関連データを削除
CartItem.delete_all
Cart.delete_all

# 8. アクセスログを削除
AccessLog.delete_all

# 9. 請求先情報を削除
InvoiceRecipient.delete_all

# 10. 請求基本情報を削除
InvoiceBase.delete_all

# 11. ユーザーを削除（外部キー参照があるため最初に削除）
User.delete_all

# 12. 商品価格データを削除
ProductPrice.delete_all

# 13. WOTTレベルデータを削除
WottLevel.delete_all

# SQLite環境のみ、シーケンスをリセット
if adapter == "SQLite"
  ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='users'")
  ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='wott_levels'")
end

puts "✅ Data cleanup completed"

# 外部キー制約を再有効化（SQLiteの場合）
if adapter == "SQLite"
  ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON")
end

# ユーザーIDを1番から開始（アジアビジネストラストがID: 1）
user_id_seq = 1
lstep_id_seq = 1

# Levelデータを作成（IDを明示的に指定）
level_data = [
  { id: 1, name: "アジアビジネストラスト", value: 0 },
  { id: 2, name: "総代理店", value: 1 },
  { id: 3, name: "代理店", value: 2 },
  { id: 4, name: "アドバイザー", value: 3 },
  { id: 5, name: "サロン", value: 4 },
  { id: 6, name: "クリニック", value: 5 },
  { id: 7, name: "サポーター", value: 6 },
  { id: 8, name: "お客様", value: 7 }
]

# 既存のレベルデータをクリアしてから新しいデータを作成
Level.delete_all
# SQLiteの場合はシーケンステーブルを直接更新
if ActiveRecord::Base.connection.adapter_name == 'SQLite'
  ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='levels'")
end

level_data.each do |data|
  Level.create!(
    id: data[:id],
    name: data[:name],
    value: data[:value]
  )
end

# Levelデータを取得（nameで検索）
levels = Level.all.index_by(&:name)

# デバッグ用：作成されたLevelを確認
puts "Created levels:"
levels.each do |name, level|
  puts "  #{name}: #{level.id} (value: #{level.value})"
end

# エラーハンドリング
if levels["アジアビジネストラスト"].nil?
  puts "❌ Error: 'アジアビジネストラスト' level not found!"
  exit 1
end

# WottLevelデータを作成
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
  WottLevel.create!(
    id: data[:id],
    name: data[:name],
    value: data[:value]
  )
end

# WottLevelデータを取得（nameで検索）
wott_levels = WottLevel.all.index_by(&:name)

# デバッグ用：作成されたWottLevelを確認
puts "Created WOTT levels:"
wott_levels.each do |name, wott_level|
  puts "  #{name}: #{wott_level.id} (value: #{wott_level.value})"
end

# Product fixturesを読み込み
puts "📦 Loading product fixtures..."
SeedFu.fixture_paths = [Rails.root.join('db', 'fixtures')]
SeedFu.seed

# Productデータを取得（ID 2,3,4の商品を使用）
product1 = Product.find_by(id: 1) # 骨髄幹細胞培培養上清液
product2 = Product.find_by(id: 2) # 臍帯幹細胞培培養上清液
product3 = Product.find_by(id: 3) # 歯髄幹細胞培培養上清液
product4 = Product.find_by(id: 4) # 脂肪幹細胞培培養上清液

# ProductPriceデータを作成（各レベルの価格設定）
price_data_1 = [
  { level_name: "アジアビジネストラスト", price: 8000 },
  { level_name: "総代理店", price: 26000 },
  { level_name: "代理店", price: 28000 },
  { level_name: "アドバイザー", price: 30000 },
  { level_name: "サロン", price: 40000 },
  { level_name: "クリニック", price: 40000 },
  { level_name: "サポーター", price: 36000 },
  { level_name: "お客様", price: 40000 }
]

# ProductPriceデータを作成（各レベルの価格設定）
price_data_2 = [
  { level_name: "アジアビジネストラスト", price: 16000 },
  { level_name: "総代理店", price: 20000 },
  { level_name: "代理店", price: 22000 },
  { level_name: "アドバイザー", price: 24000 },
  { level_name: "サロン", price: 30000 },
  { level_name: "クリニック", price: 30000 },
  { level_name: "サポーター", price: 28000 },
  { level_name: "お客様", price: 30000 }
]

price_data_3 = [
  { level_name: "アジアビジネストラスト", price: 16000 },
  { level_name: "総代理店", price: 20000 },
  { level_name: "代理店", price: 22000 },
  { level_name: "アドバイザー", price: 24000 },
  { level_name: "サロン", price: 30000 },
  { level_name: "クリニック", price: 30000 },
  { level_name: "サポーター", price: 28000 },
  { level_name: "お客様", price: 30000 }
]

price_data_4 = [
  { level_name: "アジアビジネストラスト", price: 16000 },
  { level_name: "総代理店", price: 20000 },
  { level_name: "代理店", price: 22000 },
  { level_name: "アドバイザー", price: 24000 },
  { level_name: "サロン", price: 30000 },
  { level_name: "クリニック", price: 30000 },
  { level_name: "サポーター", price: 28000 },
  { level_name: "お客様", price: 30000 }
]

[
  { product: product1, price_data: price_data_1 },
  { product: product2, price_data: price_data_2 },
  { product: product3, price_data: price_data_3 },
  { product: product4, price_data: price_data_4 }
].each do |product_info|
  next if product_info[:product].nil?
  product_info[:price_data].each do |data|
    level = levels[data[:level_name]]
    if level
      ProductPrice.find_or_create_by(product: product_info[:product], level: level) do |pp|
        pp.price = data[:price]
      end
    end
  end
end

# 骨髄幹細胞（高額商品）の価格データを作成
bone_marrow_stem_cell = Product.find_by(id: 5) # 骨髄幹細胞
if bone_marrow_stem_cell
  bone_marrow_price_data = [
    { level_name: "アジアビジネストラスト", price: 1900000 },
    { level_name: "総代理店", price: 3040000 },
    { level_name: "代理店", price: 3230000 },
    { level_name: "アドバイザー", price: 3420000 },
    { level_name: "サロン", price: 3800000 },
    { level_name: "クリニック", price: 3800000 },
    { level_name: "サポーター", price: 3610000 },
    { level_name: "お客様", price: 3800000 }
  ]
  
  bone_marrow_price_data.each do |data|
    level = levels[data[:level_name]]
    if level
      ProductPrice.find_or_create_by(product: bone_marrow_stem_cell, level: level) do |pp|
        pp.price = data[:price]
      end
    end
  end
  
  puts "✅ Created bone marrow stem cell pricing structure"
end

# WOTT商品の価格データを作成
wott_product = Product.find_by(id: 6) # WOTT Device
if wott_product
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
end

# MANNERSOUND商品の価格データを作成（税込価格、全レベル同一価格）
mannersound_products = Product.where(id: 7..14) # MANNERSOUND商品（ID: 7-14）
mannersound_products.each do |ms_product|
  # MANNERSOUNDは全レベル同一価格（base_priceを使用）
  price_data_ms = [
    { level_name: "アジアビジネストラスト", price: ms_product.base_price },
    { level_name: "総代理店", price: ms_product.base_price },
    { level_name: "代理店", price: ms_product.base_price },
    { level_name: "アドバイザー", price: ms_product.base_price },
    { level_name: "サロン", price: ms_product.base_price },
    { level_name: "クリニック", price: ms_product.base_price },
    { level_name: "サポーター", price: ms_product.base_price },
    { level_name: "お客様", price: ms_product.base_price }
  ]
  
  price_data_ms.each do |data|
    level = levels[data[:level_name]]
    if level
      ProductPrice.find_or_create_by(product: ms_product, level: level) do |pp|
        pp.price = data[:price]
      end
    end
  end
end

puts "✅ Created MANNERSOUND products pricing structure"

# 最上位
company = User.create!(
  id: user_id_seq,
  name: "アジアビジネストラスト",
  email: "info@abt-saisei.com",
  password: "111111",
  level_id: levels["アジアビジネストラスト"].id,
  wott_level_id: wott_levels["アジアビジネストラスト"].id,
  lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
  confirmed_at: Time.current,
  admin: true  # 管理者フラグを設定
)
user_id_seq += 1
lstep_id_seq += 1

# クリニック情報を作成（アジアビジネストラストの直下、ID: 2-5）
puts "🏥 Creating clinic users..."
clinic_level = levels["クリニック"]
wott_clinic_level = wott_levels["クリニック"]

clinics_data = [
  {
    name: "銀座中央クリニック",
    postal_code: "104-0061",
    address: "東京都中央区銀座７丁目８−８ Isgビル 7F",
    phone: "03-6280-6901",
    email: "ginze-central-clinic@example.com"
  },
  {
    name: "ティファクリニック大宮院",
    postal_code: "330-0844",
    address: "埼玉県さいたま市大宮区下町１丁目４５ 松亀センタービル 1F",
    phone: "048-788-5926",
    email: "tifa-omiya@example.com"
  },
  {
    name: "ティファクリニック横浜院",
    postal_code: "220-0004",
    address: "神奈川県横浜市西区北幸1-1-8 エキニア横浜 7F 705",
    phone: "045-509-1932",
    email: "tifa-yokohama@example.com"
  },
  {
    name: "ティファクリニック新宿東口院",
    postal_code: "160-0022",
    address: "東京都新宿区新宿3-21-6 龍生堂ビル 7F",
    phone: "03-6416-0193",
    email: "tifa-shinjuku-east@example.com"
  }
]

clinics_data.each_with_index do |clinic_data, index|
  user = User.create!(
    id: user_id_seq,
    name: clinic_data[:name],
    phone: clinic_data[:phone],
    email: clinic_data[:email],
    level_id: clinic_level.id,
    wott_level_id: wott_clinic_level.id,
    referred_by_id: company.id,  # アジアビジネストラストの直下に配置
    password: "clinic_password_#{index + 1}",
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  
  # invoice_baseを作成
  InvoiceBase.create!(
    user_id: user.id,
    company_name: clinic_data[:name],
    postal_code: clinic_data[:postal_code],
    address: clinic_data[:address],
    email: clinic_data[:email]
  )
  
  user_id_seq += 1
  lstep_id_seq += 1
end

puts "✅ Created #{clinics_data.length} clinic users under アジアビジネストラスト (ID: 2-5)"

# 総代理店（level: 総代理店）
special_agent_names = ["田中美咲", "佐藤花音", "山田優香"]
special_agents = special_agent_names.map.with_index do |name, i|
  # 田中美咲だけWOTTレベルを代理店にする（違いを作るため）
  wott_level = (name == "田中美咲") ? wott_levels["代理店"] : wott_levels["総代理店"]
  
  user = User.create!(
    id: user_id_seq,
    name: name,
    email: "special_agent#{i + 1}@example.com",
    password: "111111",
    level_id: levels["総代理店"].id,
    wott_level_id: wott_level.id,
    referred_by_id: company.id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1
  user
end

# 代理店
agent_names = [
  ["鈴木愛美", "高橋彩花"], # 田中美咲の下位
  ["伊藤真由", "渡辺麻衣"], # 佐藤花音の下位
  ["小林沙織", "加藤美穂"]  # 山田優香の下位
]
agents = []
special_agents.each_with_index do |parent, i|
  agent_names[i].each_with_index do |name, j|
    # 鈴木愛美と伊藤真由をWOTTレベルでサポーターにする（違いを作るため）
    wott_level = (name == "鈴木愛美" || name == "伊藤真由") ? wott_levels["サポーター"] : wott_levels["代理店"]
    
    user = User.create!(
      id: user_id_seq,
      name: name,
      email: "agent#{i + 1}-#{j + 1}@example.com",
      password: "111111",
      level_id: levels["代理店"].id,
      wott_level_id: wott_level.id,
      referred_by_id: parent.id,
      lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
      confirmed_at: Time.current
    )
    user_id_seq += 1
    lstep_id_seq += 1
    agents << user
  end
end

# アドバイザー
advisor_names = [
  ["中村結衣", "林美里"],     # 鈴木愛美の下位
  ["森川桃子", "清水香織"],   # 高橋彩花の下位
  ["石川千夏", "松本優子"],   # 伊藤真由の下位
  ["井上美奈", "木村理恵"],   # 渡辺麻衣の下位
  ["斎藤由美", "橋本恵子"],   # 小林沙織の下位
  ["山口智子", "吉田美和"]    # 加藤美穂の下位
]
advisors = []
agents.each_with_index do |parent, i|
  advisor_names[i].each_with_index do |name, j|
    # アドバイザーはWOTTレベルにないので、基本的にサポーターにマッピング
    # 中村結衣と森川桃子をお客様レベルにする（違いを作るため）
    wott_level = (name == "中村結衣" || name == "森川桃子") ? wott_levels["お客様"] : wott_levels["サポーター"]
    
    user = User.create!(
      id: user_id_seq,
      name: name,
      email: "advisor#{i + 1}-#{j + 1}@example.com",
      password: "111111",
      level_id: levels["アドバイザー"].id,
      wott_level_id: wott_level.id,
      referred_by_id: parent.id,
      lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
      confirmed_at: Time.current
    )
    user_id_seq += 1
    lstep_id_seq += 1
    advisors << user
  end
end

# サロン・クリニック
salon_clinic_names = [
  ["美容サロン花音", "田中クリニック"],   # 中村結衣の下位
  ["エステ美里", "林医院"],             # 林美里の下位
  ["サロン桃花", "森川皮膚科"],         # 森川桃子の下位
  ["ビューティー香織", "清水内科"],     # 清水香織の下位
  ["夏美サロン", "石川美容外科"],       # 石川千夏の下位
  ["優子エステ", "松本クリニック"],     # 松本優子の下位
  ["美奈サロン", "井上医院"],           # 井上美奈の下位
  ["理恵美容室", "木村皮膚科"],         # 木村理恵の下位
  ["由美サロン", "斎藤クリニック"],     # 斎藤由美の下位
  ["恵子エステ", "橋本医院"],           # 橋本恵子の下位
  ["智子サロン", "山口美容外科"],       # 山口智子の下位
  ["美和エステ", "吉田クリニック"]      # 吉田美和の下位
]
advisors.each_with_index do |parent, i|
  [
    { type: "サロン", name: salon_clinic_names[i][0], email_prefix: "salon" },
    { type: "クリニック", name: salon_clinic_names[i][1], email_prefix: "clinic" }
  ].each do |type_data|
    # 一部のサロン・クリニックをお客様レベルにする（違いを作るため）
    wott_level = (type_data[:name].include?("美容サロン花音") || type_data[:name].include?("田中クリニック")) ? 
                 wott_levels["お客様"] : wott_levels[type_data[:type]]
    
    User.create!(
      id: user_id_seq,
      name: type_data[:name],
      email: "#{type_data[:email_prefix]}#{i + 1}@example.com",
      password: "111111",
      level_id: levels[type_data[:type]].id,
      wott_level_id: wott_level.id,
      referred_by_id: parent.id,
      lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
      confirmed_at: Time.current
    )
    user_id_seq += 1
    lstep_id_seq += 1
  end
end

# --- 追加パターン (1): サポーターレベルのユーザー ---
supporter_names = ["青木美香", "西田真理"]
supporter_customer_names = ["美香さんのお客様", "真理さんのお客様"]

2.times do |i|
  # 青木美香をWOTTレベルでお客様にする（違いを作るため）
  wott_level = (supporter_names[i] == "青木美香") ? wott_levels["お客様"] : wott_levels["サポーター"]
  
  supporter = User.create!(
    id: user_id_seq,
    name: supporter_names[i],
    email: "supporter#{i + 1}@example.com",
    password: "111111",
    level_id: levels["サポーター"].id,
    wott_level_id: wott_level.id,
    referred_by_id: special_agents[0].id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1

  # サポーターの下にお客様を作成
  User.create!(
    id: user_id_seq,
    name: supporter_customer_names[i],
    email: "supporter_customer#{i + 1}@example.com",
    password: "111111",
    level_id: levels["お客様"].id,
    wott_level_id: wott_levels["お客様"].id,
    referred_by_id: supporter.id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1

  # 青木美香（最初のサポーター）の下にサロンとクリニックを追加
  if i == 0  # 青木美香の場合のみ
    # サロンを作成
    User.create!(
      id: user_id_seq,
      name: "美香サロン",
      email: "aoki_salon@example.com",
      password: "111111",
      level_id: levels["サロン"].id,
      wott_level_id: wott_levels["サロン"].id,
      referred_by_id: supporter.id,
      lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
      confirmed_at: Time.current
    )
    user_id_seq += 1
    lstep_id_seq += 1

    # クリニックを作成
    User.create!(
      id: user_id_seq,
      name: "美香クリニック",
      email: "aoki_clinic@example.com",
      password: "111111",
      level_id: levels["クリニック"].id,
      wott_level_id: wott_levels["クリニック"].id,
      referred_by_id: supporter.id,
      lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
      confirmed_at: Time.current
    )
    user_id_seq += 1
    lstep_id_seq += 1
  end
end

# --- 追加パターン (2) ---
additional_salon_names_2 = ["花音サロン", "美容室彩花"]

2.times do |i|
  User.create!(
    id: user_id_seq,
    name: additional_salon_names_2[i],
    email: "special2_salon#{i + 1}@example.com",
    password: "111111",
    level_id: levels["サロン"].id,
    wott_level_id: wott_levels["サロン"].id,
    referred_by_id: special_agents[1].id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1
end

# --- 追加パターン (3) ---
additional_advisor_names_3 = [
  ["長谷川優花", "田村美咲"],  # 第1グループ
  ["村田彩乃", "原田美優"]     # 第2グループ
]
additional_salon_names_3 = ["優花サロン", "彩乃エステ"]

2.times do |i|
  advisor1 = User.create!(
    id: user_id_seq,
    name: additional_advisor_names_3[i][0],
    email: "special3_advisor#{i + 1}_1@example.com",
    password: "111111",
    level_id: levels["アドバイザー"].id,
    wott_level_id: wott_levels["サポーター"].id,
    referred_by_id: special_agents[2].id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1

  advisor2 = User.create!(
    id: user_id_seq,
    name: additional_advisor_names_3[i][1],
    email: "special3_advisor#{i + 1}_2@example.com",
    password: "111111",
    level_id: levels["アドバイザー"].id,
    wott_level_id: wott_levels["サポーター"].id,
    referred_by_id: advisor1.id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1

  User.create!(
    id: user_id_seq,
    name: additional_salon_names_3[i],
    email: "special3_salon#{i + 1}@example.com",
    password: "111111",
    level_id: levels["サロン"].id,
    wott_level_id: wott_levels["サロン"].id,
    referred_by_id: advisor2.id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1
end

# seller_priceを取得するヘルパーメソッド
def get_seller_price(product, user)
  user_level = user.level
  product_price = ProductPrice.find_by(product: product, level: user_level)
  product_price&.price || product.base_price
end

# 購入データの作成（新しいデータ構造に対応）
puts "🛒 Creating purchase data..."

# 商品を取得（ID 2,3,4の商品を使用）
products = [product2, product3, product4].compact
if products.empty?
  puts "⚠️  No products found. Skipping purchase data creation."
else
  # 田中美咲が自分で購入するデータを作成
  special_agent_1 = User.find_by(name: "田中美咲")
  
  if special_agent_1
    # 複数月の購入データを作成（データ量を半分に）
    months = [
      { month: "2025-09", day: 15, quantity: 20 },
      { month: "2025-10", day: 5, quantity: 25 }
    ]
    
    months.each_with_index do |month_data, month_idx|
      purchase = Purchase.create!(
        user_id: special_agent_1.id,        # 購入者
        purchased_at: "#{month_data[:month]}-#{format('%02d', month_data[:day])} 10:00:00"
      )
      
      # 複数商品を購入
      products.each_with_index do |product, product_idx|
        quantity = month_data[:quantity] / products.length + (product_idx == 0 ? month_data[:quantity] % products.length : 0)
        PurchaseItem.create!(
          purchase: purchase,
          product: product,
          quantity: quantity,
          unit_price: 30000,
          seller_price: get_seller_price(product, special_agent_1)
        )
      end
    end
    
    puts "✅ Created purchase data for 田中美咲 (9月, 10月、データ量を半分に削減)"
    
    # 他の代理店の購入データも複数月で作成（データ量を半分に）
    agents.first(2).each_with_index do |agent, i|
      months.each_with_index do |month_data, month_idx|
        # 10月は1-17日の範囲に収める
        day = if month_data[:month] == "2025-10"
                6 + i + month_idx  # 6日から開始して重複を避ける
              else
                10 + i + month_idx
              end
        purchase = Purchase.create!(
          user_id: agent.id,        # 購入者
          purchased_at: "#{month_data[:month]}-#{format('%02d', day)} 14:00:00"
        )
        
        # 複数商品を購入
        products.each_with_index do |product, product_idx|
          base_quantity = 10 + (i * 3) + (month_idx * 2)
          quantity = base_quantity / products.length + (product_idx == 0 ? base_quantity % products.length : 0)
          PurchaseItem.create!(
            purchase: purchase,
            product: product,
            quantity: quantity,
            unit_price: 30000,
            seller_price: get_seller_price(product, agent)
          )
        end
      end
    end
    
    puts "✅ Created purchase data for agents (9月, 10月、データ量を半分に削減)"
    
    # 中村結衣さんの自己購入データを作成（10月に4回のみ）
    nakamura = User.find_by(name: "中村結衣")
    if nakamura
      # 10月に4回購入（1日〜17日の範囲）
      purchase_days = [1, 5, 9, 13]  # 10月1, 5, 9, 13日
      purchase_days.each_with_index do |day, day_idx|
        purchase = Purchase.create!(
          user_id: nakamura.id,
          purchased_at: "2025-10-#{format('%02d', day)} 16:00:00"
        )
        
        # 日によって異なる商品を購入
        product = products[day_idx % products.length]
        PurchaseItem.create!(
          purchase: purchase,
          product: product,
          quantity: 7,
          unit_price: 30000,
          seller_price: get_seller_price(product, nakamura)
        )
      end
      puts "✅ Created purchase data for 中村結衣 (10月に4回)"
    end
    
    # 他のアドバイザーの購入データ（中村結衣以外、データ量を半分に）
    other_advisors = advisors.reject { |advisor| advisor.name == "中村結衣" }
    other_advisors.first(1).each_with_index do |advisor, i|
      # 10月のみ購入
      purchase = Purchase.create!(
        user_id: advisor.id,        # 購入者
        purchased_at: "2025-10-15 16:00:00"
      )
      
      # 複数商品を購入
      products.each_with_index do |product, product_idx|
        base_quantity = 6
        quantity = base_quantity / products.length + (product_idx == 0 ? base_quantity % products.length : 0)
        PurchaseItem.create!(
          purchase: purchase,
          product: product,
          quantity: quantity,
          unit_price: 30000,
          seller_price: get_seller_price(product, advisor)
        )
      end
    end
    
    puts "✅ Created purchase data for advisors (10月のみ、データ量を半分に削減)"
    
    # サポーターの購入データを作成（データ量を半分に）
    supporters = User.joins(:level).where(levels: { name: "サポーター" })
    supporters.first(1).each_with_index do |supporter, i|
      # 10月のみ購入
      purchase = Purchase.create!(
        user_id: supporter.id,
        purchased_at: "2025-10-02 18:00:00"
      )
      
      # 複数商品を購入
      products.each_with_index do |product, product_idx|
        base_quantity = 4
        quantity = base_quantity / products.length + (product_idx == 0 ? base_quantity % products.length : 0)
        PurchaseItem.create!(
          purchase: purchase,
          product: product,
          quantity: quantity,
          unit_price: 30000,
          seller_price: get_seller_price(product, supporter)
        )
      end
    end
    
    puts "✅ Created purchase data for supporters (10月のみ、データ量を半分に削減)"
  end
end

# お客様データの追加
puts "👥 Creating customer data..."

customer_names = [
  # 総代理店の直接お客様
  "山田太郎", "佐藤花子", "田中一郎", "鈴木美咲", "高橋健太", "伊藤由美",
  # 代理店の直接お客様  
  "渡辺直樹", "小林恵子", "加藤雅人", "森田真理", "清水智子", "石川大輔",
  "松本香織", "井上裕子", "木村正男", "斎藤美穂", "橋本和也", "山口千春",
  # アドバイザーの直接お客様
  "吉田博文", "中村愛子", "田村健一", "佐々木美和", "藤田直子", "岡田雄介",
  "村上香織", "長谷川太郎", "青木美香", "西田真理", "原田美優", "長谷川優花",
  "田村美咲", "村田彩乃", "川口智子", "大野裕子", "内田健太", "小川美穂",
  # サロン・クリニックのお客様
  "竹内雅人", "菊池恵子", "野口直樹", "坂本香織", "今井太郎", "宮本花子",
  "福田一郎", "岩田美咲", "上田健太", "杉山由美", "新井直樹", "池田恵子",
  "古川雅人", "平野真理", "横山智子", "安田大輔", "三浦香織", "中島裕子",
  "島田正男", "金子美穂"
]

customers = []
customer_index = 0

# 1. 総代理店の直接お客様（各総代理店に2名）
special_agents.each_with_index do |special_agent, i|
  2.times do |j|
    customer_name = customer_names[customer_index]
    customer = User.create!(
      id: user_id_seq,
      name: customer_name,
      email: "special_customer#{i + 1}-#{j + 1}@example.com",
      password: "111111",
      level_id: levels["お客様"].id,
      wott_level_id: wott_levels["お客様"].id,
      referred_by_id: special_agent.id,
      lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
      confirmed_at: Time.current
    )
    user_id_seq += 1
    lstep_id_seq += 1
    customers << customer
    customer_index += 1
  end
end

# 2. 代理店の直接お客様（各代理店に2名）
agents.each_with_index do |agent, i|
  2.times do |j|
    customer_name = customer_names[customer_index]
    customer = User.create!(
      id: user_id_seq,
      name: customer_name,
      email: "agent_customer#{i + 1}-#{j + 1}@example.com",
      password: "111111",
      level_id: levels["お客様"].id,
      wott_level_id: wott_levels["お客様"].id,
      referred_by_id: agent.id,
      lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
      confirmed_at: Time.current
    )
    user_id_seq += 1
    lstep_id_seq += 1
    customers << customer
    customer_index += 1
  end
end

# 3. アドバイザーの直接お客様（各アドバイザーに2名）
advisors.each_with_index do |advisor, i|
  2.times do |j|
    customer_name = customer_names[customer_index]
    customer = User.create!(
      id: user_id_seq,
      name: customer_name,
      email: "advisor_customer#{i + 1}-#{j + 1}@example.com",
      password: "111111",
      level_id: levels["お客様"].id,
      wott_level_id: wott_levels["お客様"].id,
      referred_by_id: advisor.id,
      lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
      confirmed_at: Time.current
    )
    user_id_seq += 1
    lstep_id_seq += 1
    customers << customer
    customer_index += 1
  end
end

# 4. サロン・クリニックの直接お客様（各サロン・クリニックに1名）
salons_and_clinics = User.joins(:level).where(levels: { value: [4, 5] })
salons_and_clinics.first(20).each_with_index do |salon_clinic, i|
  customer_name = customer_names[customer_index]
  customer = User.create!(
    id: user_id_seq,
    name: customer_name,
    email: "salon_customer#{i + 1}@example.com",
    password: "111111",
    level_id: levels["お客様"].id,
    wott_level_id: wott_levels["お客様"].id,
    referred_by_id: salon_clinic.id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1
  customers << customer
  customer_index += 1
end

puts "✅ Created #{customers.count} customers across all levels"

# お客様の購入データを作成
puts "🛒 Creating customer purchase data..."

if products.any?
  # 各レベルのお客様から一部を選んで購入データを作成
  
  # 総代理店のお客様（6名中2名が購入、データ量を半分に）
  special_customers = customers.select { |c| c.email.include?('special_customer') }
  special_customers.first(2).each_with_index do |customer, i|
    # 10月のみ購入
    purchase = Purchase.create!(
      user_id: customer.id,
      purchased_at: "2025-10-#{format('%02d', 3 + i)} 12:00:00"
    )
    
    # 顧客ごとに異なる商品を購入
    product = products[i % products.length]
    PurchaseItem.create!(
      purchase: purchase,
      product: product,
      quantity: 1,
      unit_price: 30000,
      seller_price: get_seller_price(product, customer)
    )
  end
  
  # 代理店のお客様（12名中3名が購入、データ量を半分に）
  agent_customers = customers.select { |c| c.email.include?('agent_customer') }
  agent_customers.first(3).each_with_index do |customer, i|
    # 10月のみ購入
    purchase = Purchase.create!(
      user_id: customer.id,
      purchased_at: "2025-10-#{format('%02d', 8 + i)} 14:00:00"
    )
    
    # 顧客ごとに異なる商品を購入
    product = products[i % products.length]
    PurchaseItem.create!(
      purchase: purchase,
      product: product,
      quantity: 1,
      unit_price: 30000,
      seller_price: get_seller_price(product, customer)
    )
  end
  
  # 中村結衣さんの直下位お客様のみ購入（吉田博文、中村愛子、データ量を半分に）
  nakamura_customers = customers.select { |c| 
    c.email.include?('advisor_customer1-1') || c.email.include?('advisor_customer1-2')
  }
  
  nakamura_customers.each_with_index do |customer, i|
    # 10月に1回購入
    purchase = Purchase.create!(
      user_id: customer.id,
      purchased_at: "2025-10-#{format('%02d', 5 + i)} 16:00:00"
    )
    
    # 顧客ごとに異なる商品を購入
    product = products[i % products.length]
    PurchaseItem.create!(
      purchase: purchase,
      product: product,
      quantity: 1,
      unit_price: 30000,
      seller_price: get_seller_price(product, customer)
    )
  end
  
  # 中村結衣さんの間接的なお客様（サロン・クリニック経由、データ量を半分に）
  # 福田一郎（salon_customer1）のみ購入
  indirect_customers = customers.select { |c| 
    c.email.include?('salon_customer1@')
  }
  
  indirect_customers.each_with_index do |customer, i|
    # 10月に1回購入
    purchase = Purchase.create!(
      user_id: customer.id,
      purchased_at: "2025-10-10 18:00:00"
    )
    
    # 顧客ごとに異なる商品を購入
    product = products[i % products.length]
    PurchaseItem.create!(
      purchase: purchase,
      product: product,
      quantity: 1,
      unit_price: 30000,
      seller_price: get_seller_price(product, customer)
    )
  end
  
  # サポーターが紹介したサロン・クリニックの購入データを作成（各1行ずつ）
  aoki_salon = User.find_by(name: "美香サロン")
  aoki_clinic = User.find_by(name: "美香クリニック")
  
  if aoki_salon && aoki_clinic
    # 美香サロンの購入（臍帯幹細胞のみ）
    purchase_salon = Purchase.create!(
      user_id: aoki_salon.id,
      purchased_at: "2025-10-14 15:00:00"
    )
    
    PurchaseItem.create!(
      purchase: purchase_salon,
      product: products[0],  # 臍帯幹細胞（products[0]）
      quantity: 6,
      unit_price: 30000,
      seller_price: get_seller_price(products[0], aoki_salon)
    )
    
    # 美香クリニックの購入（歯髄幹細胞のみ）
    purchase_clinic = Purchase.create!(
      user_id: aoki_clinic.id,
      purchased_at: "2025-10-15 15:00:00"
    )
    
    PurchaseItem.create!(
      purchase: purchase_clinic,
      product: products[1],  # 歯髄幹細胞（products[1]）
      quantity: 8,
      unit_price: 30000,
      seller_price: get_seller_price(products[1], aoki_clinic)
    )
    
    puts "✅ Created purchase data for supporter's salon/clinic (2 rows)"
  end

  puts "✅ Created purchase data for customers (10月のみ、データ量を半分に削減)"
  puts "   - Special agent customers: 2 customers purchasing"
  puts "   - Agent customers: 3 customers purchasing"  
  puts "   - Advisor customers: 2 customers purchasing"
  puts "   - Salon/Clinic customers: 1 customer purchasing"
  puts "   - Supporter's salon/clinic: 2 users purchasing"
end

puts "✅ Seeding completed!"