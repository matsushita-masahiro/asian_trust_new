puts "🔄 Seeding started......"

# Load fixtures
require 'seed-fu'
require 'set'

adapter = ActiveRecord::Base.connection.adapter_name

# データを適切な順序で削除（外部キー制約を考慮）
puts "🗑️ Cleaning existing data..."

# 外部キー制約を一時的に無効化（SQLiteの場合）
if adapter == "SQLite"
  ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF")
end

# 1. 購入請求書関連データを削除
PurchaseInvoice.delete_all

# 2. 送料データを削除（purchasesを参照しているため先に削除）
ShippingFee.delete_all

# 3. 配送情報を削除（purchasesを参照しているため先に削除）
DeliveryInformation.delete_all

# 4. クリニック予約を削除（purchasesを参照しているため先に削除）
ClinicReservation.delete_all

# 5. 購入関連データを削除
PurchaseItem.delete_all
Purchase.delete_all

# 6. 請求書関連データを削除
Invoice.delete_all

# 7. レベル変更申請を削除
LevelChangeApplication.delete_all

# 8. 紹介招待を削除
ReferralInvitation.delete_all

# 9. ユーザーレベル履歴を削除
UserLevelHistory.delete_all

# 10. カート関連データを削除
CartItem.delete_all
Cart.delete_all

# 11. アクセスログを削除
AccessLog.delete_all

# 12. 住所データを削除（usersを参照しているため先に削除）
Address.delete_all

# 13. 請求先情報を削除
InvoiceRecipient.delete_all

# 14. 請求基本情報を削除
InvoiceBase.delete_all

# 15. ユーザーを削除（外部キー参照があるため最後に削除）
User.delete_all

# 16. 商品価格データを削除
ProductPrice.delete_all

# 17. WOTTレベルデータを削除
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
  { id: 5, name: "アドバイザー認定前", value: 4 },
  { id: 6, name: "サポーター", value: 5 },
  { id: 7, name: "クリニック", value: 6 },
  { id: 8, name: "サロン", value: 7 },
  { id: 9, name: "お客様", value: 8 }
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
  { level_name: "サポーター", price: 36000 },
  { level_name: "サロン", price: 40000 },
  { level_name: "クリニック", price: 40000 },
  { level_name: "お客様", price: 40000 }
]

# ProductPriceデータを作成（各レベルの価格設定）
price_data_2 = [
  { level_name: "アジアビジネストラスト", price: 16000 },
  { level_name: "総代理店", price: 20000 },
  { level_name: "代理店", price: 22000 },
  { level_name: "アドバイザー", price: 24000 },
  { level_name: "サポーター", price: 28000 },
  { level_name: "サロン", price: 30000 },
  { level_name: "クリニック", price: 30000 },
  { level_name: "お客様", price: 30000 }
]

price_data_3 = [
  { level_name: "アジアビジネストラスト", price: 16000 },
  { level_name: "総代理店", price: 20000 },
  { level_name: "代理店", price: 22000 },
  { level_name: "アドバイザー", price: 24000 },
  { level_name: "サポーター", price: 28000 },
  { level_name: "サロン", price: 30000 },
  { level_name: "クリニック", price: 30000 },
  { level_name: "お客様", price: 30000 }
]

price_data_4 = [
  { level_name: "アジアビジネストラスト", price: 16000 },
  { level_name: "総代理店", price: 20000 },
  { level_name: "代理店", price: 22000 },
  { level_name: "アドバイザー", price: 24000 },
  { level_name: "サポーター", price: 28000 },
  { level_name: "サロン", price: 30000 },
  { level_name: "クリニック", price: 30000 },
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
    { level_name: "サポーター", price: 3610000 },
    { level_name: "サロン", price: 3800000 },
    { level_name: "クリニック", price: 3800000 },
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
    { level_name: "サポーター", price: ms_product.base_price },
    { level_name: "サロン", price: ms_product.base_price },
    { level_name: "クリニック", price: ms_product.base_price },
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

# 電話番号の重複を避けるためのヘルパーメソッド
def generate_unique_phone(base_number, existing_phones)
  phone = base_number
  counter = 1
  while existing_phones.include?(phone)
    # 末尾の数字を変更して重複を避ける
    phone = base_number.gsub(/\d{4}$/) { |match| format('%04d', match.to_i + counter) }
    counter += 1
  end
  existing_phones << phone
  phone
end

# 使用済み電話番号を追跡するSet
used_phones = Set.new

# 最上位
company = User.create!(
  id: user_id_seq,
  name: "アジアビジネストラスト",
  email: "info@abt-saisei.com",
  password: "111111",
  phone: generate_unique_phone("03-1234-5678", used_phones),
  level_id: levels["アジアビジネストラスト"].id,
  wott_level_id: wott_levels["アジアビジネストラスト"].id,
  lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
  confirmed_at: Time.current,
  admin: true  # 管理者フラグを設定
)
user_id_seq += 1
lstep_id_seq += 1

# クリニック情報は最後に作成（最下部に表示するため）

# === 新しい階層構造：アジアビジネストラスト直下のアドバイザーとその下位 ===
puts "👤 Creating new advisor hierarchy under アジアビジネストラスト..."

# アドバイザー（アジアビジネストラストの直下）
test_advisor = User.create!(
  id: user_id_seq,
  name: "テスト太郎",
  email: "test_advisor@example.com",
  password: "111111",
  phone: generate_unique_phone("090-9999-0001", used_phones),
  level_id: levels["アドバイザー"].id,
  wott_level_id: wott_levels["サポーター"].id,
  referred_by_id: company.id,  # アジアビジネストラストの直下
  lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
  confirmed_at: Time.current
)
user_id_seq += 1
lstep_id_seq += 1

# 1. アドバイザーの直下にクリニック
test_clinic = User.create!(
  id: user_id_seq,
  name: "テストクリニック",
  email: "test_clinic@example.com",
  password: "111111",
  phone: generate_unique_phone("03-9999-0001", used_phones),
  level_id: levels["クリニック"].id,
  wott_level_id: wott_levels["クリニック"].id,
  referred_by_id: test_advisor.id,
  lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
  confirmed_at: Time.current
)
user_id_seq += 1
lstep_id_seq += 1

# 2. アドバイザーの直下にサポーター（下位なし）
test_supporter1 = User.create!(
  id: user_id_seq,
  name: "テスト花子",
  email: "test_supporter1@example.com",
  password: "111111",
  phone: generate_unique_phone("090-9999-0002", used_phones),
  level_id: levels["サポーター"].id,
  wott_level_id: wott_levels["サポーター"].id,
  referred_by_id: test_advisor.id,
  lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
  confirmed_at: Time.current
)
user_id_seq += 1
lstep_id_seq += 1

# 3. アドバイザーの直下にサポーター（下位にサロンあり）
test_supporter2 = User.create!(
  id: user_id_seq,
  name: "テスト次郎",
  email: "test_supporter2@example.com",
  password: "111111",
  phone: generate_unique_phone("090-9999-0003", used_phones),
  level_id: levels["サポーター"].id,
  wott_level_id: wott_levels["サポーター"].id,
  referred_by_id: test_advisor.id,
  lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
  confirmed_at: Time.current
)
user_id_seq += 1
lstep_id_seq += 1

# サポーター（テスト次郎）の直下にサロン
test_salon = User.create!(
  id: user_id_seq,
  name: "テストサロン",
  email: "test_salon@example.com",
  password: "111111",
  phone: generate_unique_phone("03-9999-0002", used_phones),
  level_id: levels["サロン"].id,
  wott_level_id: wott_levels["サロン"].id,
  referred_by_id: test_supporter2.id,
  lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
  confirmed_at: Time.current
)
user_id_seq += 1
lstep_id_seq += 1

puts "✅ Created test advisor hierarchy:"
puts "  - テスト太郎 (Advisor, ID: #{test_advisor.id})"
puts "    - テストクリニック (Clinic, ID: #{test_clinic.id})"
puts "    - テスト花子 (Supporter, ID: #{test_supporter1.id})"
puts "    - テスト次郎 (Supporter, ID: #{test_supporter2.id})"
puts "      - テストサロン (Salon, ID: #{test_salon.id})"

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
    phone: generate_unique_phone("090-#{1000 + i}-#{5678 + i}", used_phones),
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
      phone: generate_unique_phone("080-#{2000 + (i * 10) + j}-#{1234 + j}", used_phones),
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
      phone: generate_unique_phone("070-#{3000 + (i * 10) + j}-#{2345 + j}", used_phones),
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

# アドバイザー認定前のユーザーを作成（代理店の直下に2人）
# 注意：アドバイザー認定前は紹介機能が使えないため、下位ユーザーは作成しない
advisor_pre_names = ["山田花音", "佐藤美里"]
advisor_pres = []

# 最初の代理店（鈴木愛美）の直下に2人のアドバイザー認定前を作成
first_agent = agents.first
advisor_pre_names.each_with_index do |name, i|
  user = User.create!(
    id: user_id_seq,
    name: name,
    email: "advisor_pre#{i + 1}@example.com",
    password: "111111",
    phone: generate_unique_phone("060-#{4000 + i}-#{3456 + i}", used_phones),
    level_id: levels["アドバイザー認定前"].id,
    wott_level_id: wott_levels["サポーター"].id, # WOTTレベルはサポーターにマッピング
    referred_by_id: first_agent.id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1
  advisor_pres << user
end

puts "✅ Created #{advisor_pre_names.length} advisor pre-certification users under #{first_agent.name} (no subordinates - referral function disabled)"

# 中村結衣（最初のアドバイザー）の直下にサポーターを作成し、そのサポーターの直下にサロンを作成
nakamura_yuui = advisors[0]  # 中村結衣
nakamura_supporter = User.create!(
  id: user_id_seq,
  name: "佐々木結衣",
  email: "nakamura_supporter@example.com",
  password: "111111",
  phone: generate_unique_phone("080-5500-1234", used_phones),
  level_id: levels["サポーター"].id,
  wott_level_id: wott_levels["サポーター"].id,
  referred_by_id: nakamura_yuui.id,
  lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
  confirmed_at: Time.current
)
user_id_seq += 1
lstep_id_seq += 1

# サポーターの直下にサロンを作成
nakamura_salon = User.create!(
  id: user_id_seq,
  name: "美容サロン花音",
  email: "nakamura_salon@example.com",
  password: "111111",
  phone: generate_unique_phone("03-5500-5678", used_phones),
  level_id: levels["サロン"].id,
  wott_level_id: wott_levels["サロン"].id,
  referred_by_id: nakamura_supporter.id,
  lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
  confirmed_at: Time.current
)
user_id_seq += 1
lstep_id_seq += 1

puts "✅ Created supporter (佐々木結衣) under 中村結衣 and salon (美容サロン花音) under supporter"

# サロン・クリニック（他のアドバイザーの下位）
salon_clinic_names = [
  ["田中クリニック"],                   # 中村結衣の下位（クリニックのみ）
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
  # 中村結衣の場合はクリニックのみ作成（サロンは既にサポーター経由で作成済み）
  if i == 0
    User.create!(
      id: user_id_seq,
      name: salon_clinic_names[i][0],
      email: "clinic#{i + 1}@example.com",
      password: "111111",
      phone: generate_unique_phone("050-#{4000 + (parent.id * 10) + i}-#{3456 + i}", used_phones),
      level_id: levels["クリニック"].id,
      wott_level_id: wott_levels["クリニック"].id,
      referred_by_id: parent.id,
      lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
      confirmed_at: Time.current
    )
    user_id_seq += 1
    lstep_id_seq += 1
  else
    # 他のアドバイザーは通常通りサロンとクリニックを作成
    [
      { type: "サロン", name: salon_clinic_names[i][0], email_prefix: "salon" },
      { type: "クリニック", name: salon_clinic_names[i][1], email_prefix: "clinic" }
    ].each do |type_data|
      User.create!(
        id: user_id_seq,
        name: type_data[:name],
        email: "#{type_data[:email_prefix]}#{i + 1}@example.com",
        password: "111111",
        phone: generate_unique_phone("050-#{4000 + (parent.id * 10) + i}-#{3456 + i}", used_phones),
        level_id: levels[type_data[:type]].id,
        wott_level_id: wott_levels[type_data[:type]].id,
        referred_by_id: parent.id,
        lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
        confirmed_at: Time.current
      )
      user_id_seq += 1
      lstep_id_seq += 1
    end
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
    phone: generate_unique_phone("060-#{5000 + i}-#{4567 + i}", used_phones),
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
    phone: generate_unique_phone("080-#{6000 + i}-#{5678 + i}", used_phones),
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
      phone: generate_unique_phone("03-7000-1111", used_phones),
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
      phone: generate_unique_phone("03-7000-2222", used_phones),
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
    phone: generate_unique_phone("03-#{8000 + i}-#{3333 + i}", used_phones),
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
    phone: generate_unique_phone("070-#{9000 + (i * 2)}-#{4444 + i}", used_phones),
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
    phone: generate_unique_phone("070-#{9000 + (i * 2) + 1}-#{5555 + i}", used_phones),
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
    phone: generate_unique_phone("03-#{9500 + i}-#{6666 + i}", used_phones),
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
  # === テスト階層のユーザーの購入データを作成 ===
  puts "🛒 Creating purchase data for test hierarchy..."
  
  # テスト太郎（アドバイザー）の購入
  test_advisor = User.find_by(name: "テスト太郎")
  if test_advisor
    purchase = Purchase.create!(
      user_id: test_advisor.id,
      purchased_at: "2025-11-01 09:00:00",
      status: 'paid'
    )
    
    PurchaseItem.create!(
      purchase: purchase,
      product: products[0],  # 臍帯幹細胞
      quantity: 10,
      unit_price: 30000,
      seller_price: get_seller_price(products[0], test_advisor)
    )
    puts "  Created purchase for テスト太郎 (Advisor)"
  end
  
  # テストクリニックの購入
  test_clinic = User.find_by(name: "テストクリニック")
  if test_clinic
    purchase = Purchase.create!(
      user_id: test_clinic.id,
      purchased_at: "2025-11-02 10:00:00",
      status: 'paid'
    )
    
    PurchaseItem.create!(
      purchase: purchase,
      product: products[1],  # 歯髄幹細胞
      quantity: 8,
      unit_price: 30000,
      seller_price: get_seller_price(products[1], test_clinic)
    )
    puts "  Created purchase for テストクリニック (Clinic)"
  end
  
  # テスト花子（サポーター、下位なし）の購入
  test_supporter1 = User.find_by(name: "テスト花子")
  if test_supporter1
    purchase = Purchase.create!(
      user_id: test_supporter1.id,
      purchased_at: "2025-11-03 11:00:00",
      status: 'paid'
    )
    
    PurchaseItem.create!(
      purchase: purchase,
      product: products[0],  # 臍帯幹細胞
      quantity: 5,
      unit_price: 30000,
      seller_price: get_seller_price(products[0], test_supporter1)
    )
    puts "  Created purchase for テスト花子 (Supporter)"
  end
  
  # テスト次郎（サポーター、下位にサロンあり）の購入
  test_supporter2 = User.find_by(name: "テスト次郎")
  if test_supporter2
    purchase = Purchase.create!(
      user_id: test_supporter2.id,
      purchased_at: "2025-11-04 12:00:00",
      status: 'paid'
    )
    
    PurchaseItem.create!(
      purchase: purchase,
      product: products[1],  # 歯髄幹細胞
      quantity: 6,
      unit_price: 30000,
      seller_price: get_seller_price(products[1], test_supporter2)
    )
    puts "  Created purchase for テスト次郎 (Supporter)"
  end
  
  # テストサロンの購入
  test_salon = User.find_by(name: "テストサロン")
  if test_salon
    purchase = Purchase.create!(
      user_id: test_salon.id,
      purchased_at: "2025-11-05 13:00:00",
      status: 'paid'
    )
    
    PurchaseItem.create!(
      purchase: purchase,
      product: products[2],  # 脂肪幹細胞
      quantity: 7,
      unit_price: 30000,
      seller_price: get_seller_price(products[2], test_salon)
    )
    puts "  Created purchase for テストサロン (Salon)"
  end
  
  puts "✅ Created purchase data for test hierarchy"
  
  # 田中美咲が自分で購入するデータを作成
  special_agent_1 = User.find_by(name: "田中美咲")
  
  if special_agent_1
    # 複数月の購入データを作成（2025年9月、10月、11月）
    months = [
      { month: "2025-09", day: 15, quantity: 20 },
      { month: "2025-10", day: 5, quantity: 25 },
      { month: "2025-11", day: 1, quantity: 18 }
    ]
    
    months.each_with_index do |month_data, month_idx|
      # 11月分はいろんなステータス、それ以前はpaid
      purchase_status = if month_data[:month] == "2025-11"
                          # インデックスに基づいて決定的にステータスを割り当て
                          case month_idx % 3
                          when 0 then 'built'
                          when 1 then 'paid'
                          when 2 then 'reserved'
                          end
                        else
                          'paid'
                        end
      puts "  Creating purchase for #{month_data[:month]} with status: #{purchase_status}"
      
      # 9月・10月はクレジットカード払い（status: paid）、11月は銀行振込
      payment_type = (month_data[:month] == "2025-09" || month_data[:month] == "2025-10") ? 'credit' : 'cash'
      
      purchase = Purchase.create!(
        user_id: special_agent_1.id,        # 購入者
        purchased_at: "#{month_data[:month]}-#{format('%02d', month_data[:day])} 10:00:00",
        payment_type: payment_type,
        status: purchase_status
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
        # 日付を適切に設定
        day = if month_data[:month] == "2025-10"
                6 + i + month_idx  # 6日から開始して重複を避ける
              elsif month_data[:month] == "2025-11"
                1 + i + month_idx  # 11月は1日から開始
              else
                10 + i + month_idx
              end
        # 11月分はいろんなステータス、それ以前はpaid
        purchase_status = if month_data[:month] == "2025-11"
                            case (i + month_idx) % 3
                            when 0 then 'built'
                            when 1 then 'paid'
                            when 2 then 'reserved'
                            end
                          else
                            'paid'
                          end
        
        # 9月・10月はクレジットカード払い（status: paid）、11月は銀行振込
        payment_type = (month_data[:month] == "2025-09" || month_data[:month] == "2025-10") ? 'credit' : 'cash'
        
        purchase = Purchase.create!(
          user_id: agent.id,        # 購入者
          purchased_at: "#{month_data[:month]}-#{format('%02d', day)} 14:00:00",
          payment_type: payment_type,
          status: purchase_status
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
    
    # 中村結衣さんの自己購入データを作成（9月、10月、11月）
    nakamura = User.find_by(name: "中村結衣")
    if nakamura
      # 各月に購入
      purchase_dates = [
        { date: "2025-09-10", quantity: 8 },
        { date: "2025-10-05", quantity: 7 },
        { date: "2025-10-15", quantity: 6 },
        { date: "2025-11-01", quantity: 5 }
      ]
      
      purchase_dates.each_with_index do |purchase_data, idx|
        # 11月分はいろんなステータス、それ以前はpaid
        purchase_status = if purchase_data[:date].start_with?("2025-11")
                            case idx % 3
                            when 0 then 'built'
                            when 1 then 'paid'
                            when 2 then 'reserved'
                            end
                          else
                            'paid'
                          end
        
        # 9月・10月はクレジットカード払い（status: paid）、11月は銀行振込
        payment_type = purchase_data[:date].start_with?("2025-11") ? 'cash' : 'credit'
        
        purchase = Purchase.create!(
          user_id: nakamura.id,
          purchased_at: "#{purchase_data[:date]} 16:00:00",
          payment_type: payment_type,
          status: purchase_status
        )
        
        # 日によって異なる商品を購入
        product = products[idx % products.length]
        PurchaseItem.create!(
          purchase: purchase,
          product: product,
          quantity: purchase_data[:quantity],
          unit_price: 30000,
          seller_price: get_seller_price(product, nakamura)
        )
      end
      puts "✅ Created purchase data for 中村結衣 (9月、10月、11月)"
    end
    
    # 他のアドバイザーの購入データ（中村結衣以外）
    other_advisors = advisors.reject { |advisor| advisor.name == "中村結衣" }
    other_advisors.first(2).each_with_index do |advisor, i|
      # 9月、10月、11月に購入
      purchase_dates = ["2025-09-20", "2025-10-15", "2025-11-02"]
      purchase_dates.each_with_index do |date, date_idx|
        # 11月分はいろんなステータス、それ以前はpaid
        purchase_status = if date.start_with?("2025-11")
                            case (i + date_idx) % 3
                            when 0 then 'built'
                            when 1 then 'paid'
                            when 2 then 'reserved'
                            end
                          else
                            'paid'
                          end
        
        # 9月・10月はクレジットカード払い（status: paid）、11月は銀行振込
        payment_type = date.start_with?("2025-11") ? 'cash' : 'credit'
        
        purchase = Purchase.create!(
          user_id: advisor.id,
          purchased_at: "#{date} 16:00:00",
          payment_type: payment_type,
          status: purchase_status
        )
        
        # 複数商品を購入
        products.each_with_index do |product, product_idx|
          base_quantity = 4 + date_idx
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
    end
    
    puts "✅ Created purchase data for advisors (9月、10月、11月)"
    
    # サポーターの購入データを作成
    supporters = User.joins(:level).where(levels: { name: "サポーター" })
    supporters.first(2).each_with_index do |supporter, i|
      # 9月、10月、11月に購入
      purchase_dates = ["2025-09-25", "2025-10-12", "2025-11-01"]
      purchase_dates.each_with_index do |date, date_idx|
        # 11月分はいろんなステータス、それ以前はpaid
        purchase_status = if date.start_with?("2025-11")
                            case (i + date_idx) % 3
                            when 0 then 'built'
                            when 1 then 'paid'
                            when 2 then 'reserved'
                            end
                          else
                            'paid'
                          end
        
        # 9月・10月はクレジットカード払い（status: paid）、11月は銀行振込
        payment_type = date.start_with?("2025-11") ? 'cash' : 'credit'
        
        purchase = Purchase.create!(
          user_id: supporter.id,
          purchased_at: "#{date} 18:00:00",
          payment_type: payment_type,
          status: purchase_status
        )
        
        # 複数商品を購入
        products.each_with_index do |product, product_idx|
          base_quantity = 3 + date_idx
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
    end
    
    puts "✅ Created purchase data for supporters (9月、10月、11月)"
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
      phone: generate_unique_phone("090-#{7000 + (i * 10) + j}-#{7777 + j}", used_phones),
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
      phone: generate_unique_phone("080-#{8000 + (i * 10) + j}-#{8888 + j}", used_phones),
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
      phone: generate_unique_phone("070-#{9000 + (i * 10) + j}-#{9999 + j}", used_phones),
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

# 4. サロン・クリニックの直接お客様は作成しない（紹介機能が使えないため）
# サロン・クリニックは紹介できないため、下位ユーザーは作成しない

puts "✅ Created #{customers.count} customers across all levels"

# お客様の購入データを作成
puts "🛒 Creating customer purchase data..."

if products.any?
  # 各レベルのお客様から一部を選んで購入データを作成
  
  # 総代理店のお客様（6名中3名が購入）
  special_customers = customers.select { |c| c.email.include?('special_customer') }
  special_customers.first(3).each_with_index do |customer, i|
    # 9月、10月、11月に購入
    purchase_dates = ["2025-09-#{format('%02d', 5 + i)}", "2025-10-#{format('%02d', 3 + i)}", "2025-11-01"]
    purchase_dates.each_with_index do |date, date_idx|
      # 11月分はいろんなステータス、それ以前はpaid
      purchase_status = if date.start_with?("2025-11")
                          case date_idx % 3
                          when 0 then 'built'
                          when 1 then 'paid'
                          when 2 then 'reserved'
                          end
                        else
                          'paid'
                        end
      
      # 9月・10月はクレジットカード払い（status: paid）、11月は銀行振込
      payment_type = date.start_with?("2025-11") ? 'cash' : 'credit'
      
      purchase = Purchase.create!(
        user_id: customer.id,
        purchased_at: "#{date} 12:00:00",
        payment_type: payment_type,
        status: purchase_status
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
  end
  
  # 代理店のお客様（12名中3名が購入、データ量を半分に）
  agent_customers = customers.select { |c| c.email.include?('agent_customer') }
  agent_customers.first(3).each_with_index do |customer, i|
    # 10月のみ購入
    purchase = Purchase.create!(
      user_id: customer.id,
      purchased_at: "2025-10-#{format('%02d', 8 + i)} 14:00:00",
      status: 'paid'
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
      purchased_at: "2025-10-#{format('%02d', 5 + i)} 16:00:00",
      status: 'paid'
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
      purchased_at: "2025-10-10 18:00:00",
      status: 'paid'
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
  
  # 佐々木結衣（サポーター、中村結衣の直下）の購入データを作成
  sasaki = User.find_by(name: "佐々木結衣")
  if sasaki
    # 10月に購入
    purchase = Purchase.create!(
      user_id: sasaki.id,
      purchased_at: "2025-10-12 14:00:00",
      status: 'paid'
    )
    
    PurchaseItem.create!(
      purchase: purchase,
      product: products[0],  # 臍帯幹細胞
      quantity: 5,
      unit_price: 30000,
      seller_price: get_seller_price(products[0], sasaki)
    )
    
    puts "✅ Created purchase data for 佐々木結衣 (supporter under 中村結衣)"
  end
  
  # 美容サロン花音（佐々木結衣の直下）の購入データを作成
  nakamura_salon = User.find_by(name: "美容サロン花音")
  if nakamura_salon
    # 10月に購入
    purchase = Purchase.create!(
      user_id: nakamura_salon.id,
      purchased_at: "2025-10-13 15:00:00",
      status: 'paid'
    )
    
    PurchaseItem.create!(
      purchase: purchase,
      product: products[1],  # 歯髄幹細胞
      quantity: 7,
      unit_price: 30000,
      seller_price: get_seller_price(products[1], nakamura_salon)
    )
    
    puts "✅ Created purchase data for 美容サロン花音 (salon under 佐々木結衣)"
  end
  
  # サポーターが紹介したサロン・クリニックの購入データを作成（各1行ずつ）
  aoki_salon = User.find_by(name: "美香サロン")
  aoki_clinic = User.find_by(name: "美香クリニック")
  
  if aoki_salon && aoki_clinic
    # 美香サロンの購入（臍帯幹細胞のみ）
    purchase_salon = Purchase.create!(
      user_id: aoki_salon.id,
      purchased_at: "2025-10-14 15:00:00",
      status: 'paid'
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
      purchased_at: "2025-10-15 15:00:00",
      status: 'paid'
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

# 9月・10月の全ての購入データのステータスを'paid'に更新
puts "💳 Updating Sept/Oct purchases to paid status..."
sept_oct_purchases = Purchase.where('purchased_at >= ? AND purchased_at < ?', '2025-09-01', '2025-11-01')
updated_count = sept_oct_purchases.update_all(status: 'paid', payment_type: 'credit')
puts "✅ Updated #{updated_count} purchases (Sept/Oct) to paid status"

# 全てのPurchaseに対してpurchase_invoiceを作成
puts "📄 Creating purchase invoices for all purchases..."

Purchase.includes(:purchase_items, :user).find_each do |purchase|
  next if purchase.purchase_invoice.present? # 既に存在する場合はスキップ
  
  # 請求書番号を生成
  invoice_number = PurchaseInvoice.generate_invoice_number
  
  # 購入日時から月を取得
  purchase_month = purchase.purchased_at.strftime("%Y-%m")
  
  # 9月・10月の購入は支払済み（status: 3）、11月は購入ステータスに応じて設定
  if purchase_month == "2025-09" || purchase_month == "2025-10"
    invoice_status = 3  # PAID
    invoice_sent_at = purchase.purchased_at
    invoice_paid_at = purchase.purchased_at
  else
    # 11月以降は購入ステータスに応じて設定
    # built: status = 0 (DRAFT), sent_at = nil
    # reserved: status = 1 (SENT), sent_at = 購入日時
    # paid: status = 2 (CONFIRMED), sent_at = 購入日時
    invoice_status = case purchase.status
                     when 'built' then 0
                     when 'reserved' then 1
                     when 'paid' then 2
                     else 0
                     end
    invoice_sent_at = purchase.status == 'built' ? nil : purchase.purchased_at
    invoice_paid_at = nil
  end
  
  # 請求書を作成
  purchase_invoice = purchase.create_purchase_invoice!(
    invoice_number: invoice_number,
    invoice_date: purchase.purchased_at.to_date,
    due_date: purchase.purchased_at.to_date + 1.week,
    total_amount: purchase.total_price,
    status: invoice_status,
    sent_at: invoice_sent_at,
    confirmed_at: (invoice_status == 2 || invoice_status == 3 ? purchase.purchased_at : nil)
  )
  
  status_label = case invoice_status
                 when 0 then "DRAFT"
                 when 1 then "SENT"
                 when 2 then "CONFIRMED"
                 when 3 then "PAID"
                 else "UNKNOWN"
                 end
  puts "  Created invoice #{invoice_number} for purchase #{purchase.id} (status: #{status_label})"
end

puts "✅ Created purchase invoices for all purchases (built→DRAFT, reserved→SENT, paid→CONFIRMED)"

# 全てのPurchaseに送料を設定
puts "🚚 Setting shipping fees for all purchases..."

Purchase.includes(:purchase_items, :shipping_fees).find_each do |purchase|
  next if purchase.shipping_fees.exists? # 既に送料が設定されている場合はスキップ
  
  # 購入商品に基づいて送料を自動設定
  shipping_types_used = []
  
  purchase.purchase_items.includes(:product).each do |item|
    product = item.product
    shipping_type = product.shipping_type
    
    # 同じ送料タイプが既に追加されていない場合のみ追加
    unless shipping_types_used.include?(shipping_type)
      purchase.shipping_fees.create!(
        shipping_type: shipping_type,
        amount: product.shipping_fee_amount
      )
      shipping_types_used << shipping_type
      puts "  Added #{shipping_type} shipping (¥#{product.shipping_fee_amount}) to purchase #{purchase.id}"
    end
  end
end

# InvoiceRecipientデータを作成（user_id = 1で株式会社アジアビジネストラスト）
puts "🏢 Creating InvoiceRecipient data..."

# user_id = 1のユーザー（アジアビジネストラスト）を取得
abt_user = User.find_by(id: 1)

if abt_user
  # 既存のInvoiceRecipientがあれば削除
  InvoiceRecipient.where(user_id: 1).destroy_all
  
  # 新しいInvoiceRecipientを作成
  InvoiceRecipient.create!(
    user_id: 1,
    name: "株式会社アジアビジネストラスト",
    email: "abt1@asia-b-t.com",
    postal_code: "104-0061",
    address: "東京都中央区銀座4丁目8-1銀座穂月ビル３階",
    tel: "03-5904-8148",
    representative_name: "代表取締役　道端泰代",
    bank_name: "楽天銀行",
    bank_branch_name: "第三営業支店",
    bank_account_type: "普通",
    bank_account_number: "7247552",
    bank_account_name: "株式会社アジアビジネストラスト"
  )
  
  puts "✅ Created InvoiceRecipient for 株式会社アジアビジネストラスト (user_id: 1)"
else
  puts "⚠️  User with id: 1 not found. Skipping InvoiceRecipient creation."
end

# WOTT商品の購入履歴を作成
puts "🔧 Creating WOTT product purchase data..."

wott_product = Product.find_by(id: 6) # WOTT Device
if wott_product
  # === (1) プロモートチーム本人の購入 ===
  
  # 田中美咲（総代理店、WOTTレベル：代理店）のWOTT自己購入
  tanaka = User.find_by(name: "田中美咲")
  if tanaka && tanaka.wott_level && ['総代理店', '代理店', 'サポーター'].include?(tanaka.wott_level.name)
    purchase = Purchase.create!(
      user_id: tanaka.id,
      purchased_at: "2025-10-15 10:00:00",
      status: 'paid'
    )
    
    wott_price = ProductPrice.find_by(product: wott_product, wott_level: tanaka.wott_level)&.price || wott_product.base_price
    
    PurchaseItem.create!(
      purchase: purchase,
      product: wott_product,
      quantity: 1,
      unit_price: wott_product.base_price,
      seller_price: wott_price
    )
    
    puts "  Created WOTT self-purchase for #{tanaka.name} (WOTTレベル: #{tanaka.wott_level.name}, 価格: ¥#{wott_price})"
  end
  
  # 鈴木愛美（代理店、WOTTレベル：サポーター）のWOTT自己購入
  suzuki = User.find_by(name: "鈴木愛美")
  if suzuki && suzuki.wott_level && ['総代理店', '代理店', 'サポーター'].include?(suzuki.wott_level.name)
    purchase = Purchase.create!(
      user_id: suzuki.id,
      purchased_at: "2025-11-02 14:00:00",
      status: 'paid'  # 鈴木愛美のWOTT購入は支払済み
    )
    
    wott_price = ProductPrice.find_by(product: wott_product, wott_level: suzuki.wott_level)&.price || wott_product.base_price
    
    PurchaseItem.create!(
      purchase: purchase,
      product: wott_product,
      quantity: 1,
      unit_price: wott_product.base_price,
      seller_price: wott_price
    )
    
    puts "  Created WOTT self-purchase for #{suzuki.name} (WOTTレベル: #{suzuki.wott_level.name}, 価格: ¥#{wott_price})"
  end
  
  # 青木美香（サポーター、WOTTレベル：お客様→サポーターに変更必要）
  # seeds.rbで青木美香のWOTTレベルをサポーターに設定されているか確認
  aoki = User.find_by(name: "青木美香")
  if aoki && aoki.wott_level && ['総代理店', '代理店', 'サポーター'].include?(aoki.wott_level.name)
    purchase = Purchase.create!(
      user_id: aoki.id,
      purchased_at: "2025-11-04 11:00:00",
      status: 'reserved'  # 青木美香のWOTT購入は予約完了
    )
    
    wott_price = ProductPrice.find_by(product: wott_product, wott_level: aoki.wott_level)&.price || wott_product.base_price
    
    PurchaseItem.create!(
      purchase: purchase,
      product: wott_product,
      quantity: 1,
      unit_price: wott_product.base_price,
      seller_price: wott_price
    )
    
    puts "  Created WOTT self-purchase for #{aoki.name} (WOTTレベル: #{aoki.wott_level.name}, 価格: ¥#{wott_price})"
  end
  
  # === (2) 直下位のお客様・クリニック・サロンの購入 ===
  
  # 田中美咲の直下のお客様（山田太郎）がWOTT購入
  yamada = User.find_by(name: "山田太郎")
  if yamada && yamada.referred_by_id == tanaka.id && yamada.level&.name == 'お客様'
    purchase = Purchase.create!(
      user_id: yamada.id,
      purchased_at: "2025-10-20 15:00:00",
      status: 'paid'
    )
    
    # お客様はWOTTレベルのお客様価格で購入
    customer_wott_level = WottLevel.find_by(name: 'お客様')
    wott_price = ProductPrice.find_by(product: wott_product, wott_level: customer_wott_level)&.price || wott_product.base_price
    
    PurchaseItem.create!(
      purchase: purchase,
      product: wott_product,
      quantity: 1,
      unit_price: wott_product.base_price,
      seller_price: wott_price
    )
    
    puts "  Created WOTT purchase for #{yamada.name} (お客様, 紹介者: #{tanaka.name})"
  end
  
  # 中村結衣→サポーター（佐々木結衣）の直下のサロン（美容サロン花音）がWOTT購入
  salon = User.find_by(name: "美容サロン花音")
  if salon && salon.referred_by_id && salon.level&.name == 'サロン'
    referrer = User.find(salon.referred_by_id)
    # 紹介者がプロモートチームの場合のみ
    if referrer && referrer.wott_level && ['総代理店', '代理店', 'サポーター'].include?(referrer.wott_level.name)
      purchase = Purchase.create!(
        user_id: salon.id,
        purchased_at: "2025-11-03 10:00:00",
        status: 'built'  # サロンのWOTT購入は未払い
      )
      
      # サロンはWOTTレベルのサロン価格で購入
      salon_wott_level = WottLevel.find_by(name: 'サロン')
      wott_price = ProductPrice.find_by(product: wott_product, wott_level: salon_wott_level)&.price || wott_product.base_price
      
      PurchaseItem.create!(
        purchase: purchase,
        product: wott_product,
        quantity: 1,
        unit_price: wott_product.base_price,
        seller_price: wott_price
      )
      
      puts "  Created WOTT purchase for #{salon.name} (サロン, 紹介者: #{referrer.name})"
    end
  end
  
  # アジアビジネストラストの直下のクリニック（銀座中央クリニック）がWOTT購入
  clinic = User.find_by(name: "銀座中央クリニック")
  if clinic && clinic.referred_by_id == company.id && clinic.level&.name == 'クリニック'
    purchase = Purchase.create!(
      user_id: clinic.id,
      purchased_at: "2025-11-05 14:00:00",
      status: 'paid'  # クリニックのWOTT購入は支払済み
    )
    
    # クリニックはWOTTレベルのクリニック価格で購入
    clinic_wott_level = WottLevel.find_by(name: 'クリニック')
    wott_price = ProductPrice.find_by(product: wott_product, wott_level: clinic_wott_level)&.price || wott_product.base_price
    
    PurchaseItem.create!(
      purchase: purchase,
      product: wott_product,
      quantity: 1,
      unit_price: wott_product.base_price,
      seller_price: wott_price
    )
    
    puts "  Created WOTT purchase for #{clinic.name} (クリニック, 紹介者: アジアビジネストラスト)"
  end
  
  puts "✅ Created WOTT product purchase data (self-purchases + direct referral purchases)"
else
  puts "⚠️  WOTT product (ID: 6) not found. Skipping WOTT purchase data creation."
end

# 新しく作成されたWOTT購入に対してもpurchase_invoiceと送料を設定
puts "📄 Creating invoices and shipping fees for WOTT purchases..."

Purchase.includes(:purchase_invoice, :shipping_fees).where(purchase_invoice: nil).find_each do |purchase|
  # 請求書を作成
  invoice_number = PurchaseInvoice.generate_invoice_number
  
  # 購入日時から月を取得
  purchase_month = purchase.purchased_at.strftime("%Y-%m")
  
  # 9月・10月の購入は支払済み（status: 3）、11月は購入ステータスに応じて設定
  if purchase_month == "2025-09" || purchase_month == "2025-10"
    invoice_status = 3  # PAID
    invoice_sent_at = purchase.purchased_at
  else
    # 11月以降は購入ステータスに応じて設定
    invoice_status = case purchase.status
                     when 'built' then 0
                     when 'reserved' then 1
                     when 'paid' then 2
                     else 0
                     end
    invoice_sent_at = purchase.status == 'built' ? nil : purchase.purchased_at
  end
  
  purchase.create_purchase_invoice!(
    invoice_number: invoice_number,
    invoice_date: purchase.purchased_at.to_date,
    due_date: purchase.purchased_at.to_date + 1.week,
    total_amount: purchase.total_price,
    status: invoice_status,
    sent_at: invoice_sent_at,
    confirmed_at: (invoice_status == 2 || invoice_status == 3 ? purchase.purchased_at : nil)
  )
  
  # 送料を設定
  purchase.purchase_items.includes(:product).each do |item|
    product = item.product
    unless purchase.shipping_fees.where(shipping_type: product.shipping_type).exists?
      purchase.shipping_fees.create!(
        shipping_type: product.shipping_type,
        amount: product.shipping_fee_amount
      )
    end
  end
  
  status_label = case invoice_status
                 when 0 then "DRAFT"
                 when 1 then "SENT"
                 when 2 then "CONFIRMED"
                 when 3 then "PAID"
                 else "UNKNOWN"
                 end
  puts "  Created invoice and shipping for purchase #{purchase.id} (status: #{status_label}, month: #{purchase_month})"
end

# MANNERSOUND商品の購入履歴を作成
puts "🎵 Creating MANNERSOUND product purchase data..."

mannersound_products = Product.where(id: 7..14) # MANNERSOUND商品（ID: 7-14）
if mannersound_products.any?
  # === テスト階層のMANNERSOUND購入データ ===
  
  # テスト太郎（アドバイザー）のMANNERSOUND購入
  test_advisor = User.find_by(name: "テスト太郎")
  if test_advisor
    purchase = Purchase.create!(
      user_id: test_advisor.id,
      purchased_at: "2025-11-06 09:00:00",
      status: 'paid'
    )
    
    ms_mini = mannersound_products.find_by(id: 7)
    if ms_mini
      ms_price = ProductPrice.find_by(product: ms_mini, level: test_advisor.level)&.price || ms_mini.base_price
      PurchaseItem.create!(
        purchase: purchase,
        product: ms_mini,
        quantity: 3,
        unit_price: ms_mini.base_price,
        seller_price: ms_price
      )
      puts "  Created MANNERSOUND MINI purchase for テスト太郎 (数量: 3)"
    end
  end
  
  # テストクリニックのMANNERSOUND購入
  test_clinic = User.find_by(name: "テストクリニック")
  if test_clinic
    purchase = Purchase.create!(
      user_id: test_clinic.id,
      purchased_at: "2025-11-07 10:00:00",
      status: 'paid'
    )
    
    ms_standard = mannersound_products.find_by(id: 8)
    if ms_standard
      ms_price = ProductPrice.find_by(product: ms_standard, level: test_clinic.level)&.price || ms_standard.base_price
      PurchaseItem.create!(
        purchase: purchase,
        product: ms_standard,
        quantity: 2,
        unit_price: ms_standard.base_price,
        seller_price: ms_price
      )
      puts "  Created MANNERSOUND STANDARD purchase for テストクリニック (数量: 2)"
    end
  end
  
  # テスト次郎（サポーター）のMANNERSOUND購入
  test_supporter2 = User.find_by(name: "テスト次郎")
  if test_supporter2
    purchase = Purchase.create!(
      user_id: test_supporter2.id,
      purchased_at: "2025-11-08 11:00:00",
      status: 'paid'
    )
    
    ms_mini = mannersound_products.find_by(id: 7)
    if ms_mini
      ms_price = ProductPrice.find_by(product: ms_mini, level: test_supporter2.level)&.price || ms_mini.base_price
      PurchaseItem.create!(
        purchase: purchase,
        product: ms_mini,
        quantity: 2,
        unit_price: ms_mini.base_price,
        seller_price: ms_price
      )
      puts "  Created MANNERSOUND MINI purchase for テスト次郎 (数量: 2)"
    end
  end
  
  # テストサロンのMANNERSOUND購入
  test_salon = User.find_by(name: "テストサロン")
  if test_salon
    purchase = Purchase.create!(
      user_id: test_salon.id,
      purchased_at: "2025-11-09 12:00:00",
      status: 'paid'
    )
    
    ms_mini = mannersound_products.find_by(id: 7)
    if ms_mini
      ms_price = ProductPrice.find_by(product: ms_mini, level: test_salon.level)&.price || ms_mini.base_price
      PurchaseItem.create!(
        purchase: purchase,
        product: ms_mini,
        quantity: 4,
        unit_price: ms_mini.base_price,
        seller_price: ms_price
      )
      puts "  Created MANNERSOUND MINI purchase for テストサロン (数量: 4)"
    end
  end
  
  puts "✅ Created MANNERSOUND purchase data for test hierarchy"
  
  # 田中美咲（総代理店）のMANNERSOUND購入
  tanaka = User.find_by(name: "田中美咲")
  if tanaka
    # 2025年10月に複数のMANNERSOUND商品を購入
    purchase = Purchase.create!(
      user_id: tanaka.id,
      purchased_at: "2025-10-20 11:00:00",
      status: 'paid'
    )
    
    # MANNERSOUND MINI（ID: 7）を2個購入
    ms_mini = mannersound_products.find_by(id: 7)
    if ms_mini
      ms_price = ProductPrice.find_by(product: ms_mini, level: tanaka.level)&.price || ms_mini.base_price
      PurchaseItem.create!(
        purchase: purchase,
        product: ms_mini,
        quantity: 2,
        unit_price: ms_mini.base_price,
        seller_price: ms_price
      )
      puts "  Created MANNERSOUND MINI purchase for #{tanaka.name} (数量: 2)"
    end
    
    # MANNERSOUND STANDARD（ID: 8）を1個購入
    ms_standard = mannersound_products.find_by(id: 8)
    if ms_standard
      ms_price = ProductPrice.find_by(product: ms_standard, level: tanaka.level)&.price || ms_standard.base_price
      PurchaseItem.create!(
        purchase: purchase,
        product: ms_standard,
        quantity: 1,
        unit_price: ms_standard.base_price,
        seller_price: ms_price
      )
      puts "  Created MANNERSOUND STANDARD purchase for #{tanaka.name} (数量: 1)"
    end
  end
  
  # 鈴木愛美（代理店）のMANNERSOUND購入
  suzuki = User.find_by(name: "鈴木愛美")
  if suzuki
    # 2025年11月に購入
    purchase = Purchase.create!(
      user_id: suzuki.id,
      purchased_at: "2025-11-05 14:30:00",
      status: 'reserved'  # 鈴木愛美のMANNERSOUND購入は予約完了
    )
    
    # MANNERSOUND MINI（ID: 7）を3個購入
    ms_mini = mannersound_products.find_by(id: 7)
    if ms_mini
      ms_price = ProductPrice.find_by(product: ms_mini, level: suzuki.level)&.price || ms_mini.base_price
      PurchaseItem.create!(
        purchase: purchase,
        product: ms_mini,
        quantity: 3,
        unit_price: ms_mini.base_price,
        seller_price: ms_price
      )
      puts "  Created MANNERSOUND MINI purchase for #{suzuki.name} (数量: 3)"
    end
  end
  
  # 中村結衣（アドバイザー）のMANNERSOUND購入
  nakamura = User.find_by(name: "中村結衣")
  if nakamura
    # 2025年11月に購入
    purchase = Purchase.create!(
      user_id: nakamura.id,
      purchased_at: "2025-11-08 10:00:00",
      status: 'built'  # 中村結衣のMANNERSOUND購入は未払い
    )
    
    # MANNERSOUND STANDARD（ID: 8）を1個購入
    ms_standard = mannersound_products.find_by(id: 8)
    if ms_standard
      ms_price = ProductPrice.find_by(product: ms_standard, level: nakamura.level)&.price || ms_standard.base_price
      PurchaseItem.create!(
        purchase: purchase,
        product: ms_standard,
        quantity: 1,
        unit_price: ms_standard.base_price,
        seller_price: ms_price
      )
      puts "  Created MANNERSOUND STANDARD purchase for #{nakamura.name} (数量: 1)"
    end
  end
  
  # 佐々木結衣（サポーター、中村結衣の直下）のMANNERSOUND購入
  sasaki = User.find_by(name: "佐々木結衣")
  if sasaki
    # 2025年11月に購入
    purchase = Purchase.create!(
      user_id: sasaki.id,
      purchased_at: "2025-11-09 11:00:00",
      status: 'paid'
    )
    
    # MANNERSOUND MINI（ID: 7）を2個購入
    ms_mini = mannersound_products.find_by(id: 7)
    if ms_mini
      ms_price = ProductPrice.find_by(product: ms_mini, level: sasaki.level)&.price || ms_mini.base_price
      PurchaseItem.create!(
        purchase: purchase,
        product: ms_mini,
        quantity: 2,
        unit_price: ms_mini.base_price,
        seller_price: ms_price
      )
      puts "  Created MANNERSOUND MINI purchase for #{sasaki.name} (数量: 2)"
    end
  end
  
  # 美容サロン花音（サロン、佐々木結衣の直下）のMANNERSOUND購入
  nakamura_salon = User.find_by(name: "美容サロン花音")
  if nakamura_salon
    # 2025年11月に購入
    purchase = Purchase.create!(
      user_id: nakamura_salon.id,
      purchased_at: "2025-11-10 13:00:00",
      status: 'paid'
    )
    
    # MANNERSOUND MINI（ID: 7）を4個購入
    ms_mini = mannersound_products.find_by(id: 7)
    if ms_mini
      ms_price = ProductPrice.find_by(product: ms_mini, level: nakamura_salon.level)&.price || ms_mini.base_price
      PurchaseItem.create!(
        purchase: purchase,
        product: ms_mini,
        quantity: 4,
        unit_price: ms_mini.base_price,
        seller_price: ms_price
      )
      puts "  Created MANNERSOUND MINI purchase for #{nakamura_salon.name} (数量: 4)"
    end
  end
  
  # 美香サロン（サロン）のMANNERSOUND購入
  aoki_salon = User.find_by(name: "美香サロン")
  if aoki_salon
    # 2025年11月に購入
    purchase = Purchase.create!(
      user_id: aoki_salon.id,
      purchased_at: "2025-11-10 15:00:00",
      status: 'paid'  # 美香サロンのMANNERSOUND購入は支払済み
    )
    
    # MANNERSOUND MINI（ID: 7）を5個購入
    ms_mini = mannersound_products.find_by(id: 7)
    if ms_mini
      ms_price = ProductPrice.find_by(product: ms_mini, level: aoki_salon.level)&.price || ms_mini.base_price
      PurchaseItem.create!(
        purchase: purchase,
        product: ms_mini,
        quantity: 5,
        unit_price: ms_mini.base_price,
        seller_price: ms_price
      )
      puts "  Created MANNERSOUND MINI purchase for #{aoki_salon.name} (数量: 5)"
    end
  end
  
  # 銀座中央クリニック（クリニック）のMANNERSOUND購入
  ginza_clinic = User.find_by(name: "銀座中央クリニック")
  if ginza_clinic
    # 2025年11月に購入
    purchase = Purchase.create!(
      user_id: ginza_clinic.id,
      purchased_at: "2025-11-11 09:00:00",
      status: 'reserved'  # 銀座中央クリニックのMANNERSOUND購入は予約完了
    )
    
    # MANNERSOUND STANDARD（ID: 8）を2個購入
    ms_standard = mannersound_products.find_by(id: 8)
    if ms_standard
      ms_price = ProductPrice.find_by(product: ms_standard, level: ginza_clinic.level)&.price || ms_standard.base_price
      PurchaseItem.create!(
        purchase: purchase,
        product: ms_standard,
        quantity: 2,
        unit_price: ms_standard.base_price,
        seller_price: ms_price
      )
      puts "  Created MANNERSOUND STANDARD purchase for #{ginza_clinic.name} (数量: 2)"
    end
  end
  
  puts "✅ Created MANNERSOUND product purchase data"
  
  # 新しく作成されたMANNERSOUND購入に対してもpurchase_invoiceと送料を設定
  puts "📄 Creating invoices and shipping fees for MANNERSOUND purchases..."
  
  Purchase.includes(:purchase_invoice, :shipping_fees).where(purchase_invoice: nil).find_each do |purchase|
    # 請求書を作成
    invoice_number = PurchaseInvoice.generate_invoice_number
    
    # 購入日時から月を取得
    purchase_month = purchase.purchased_at.strftime("%Y-%m")
    
    # 9月・10月の購入は支払済み（status: 3）、11月は購入ステータスに応じて設定
    invoice_status = if purchase_month == "2025-09" || purchase_month == "2025-10"
                       3  # PAID
                     else
                       case purchase.status
                       when 'built' then 0
                       when 'reserved' then 1
                       when 'paid' then 2
                       else 0
                       end
                     end
    
    invoice_sent_at = purchase.status == 'built' ? nil : purchase.purchased_at
    
    purchase.create_purchase_invoice!(
      invoice_number: invoice_number,
      invoice_date: purchase.purchased_at.to_date,
      due_date: purchase.purchased_at.to_date + 1.week,
      total_amount: purchase.total_price,
      status: invoice_status,
      sent_at: invoice_sent_at,
      confirmed_at: (invoice_status == 2 || invoice_status == 3 ? purchase.purchased_at : nil)
    )
    
    # 送料を設定
    purchase.purchase_items.includes(:product).each do |item|
      product = item.product
      unless purchase.shipping_fees.where(shipping_type: product.shipping_type).exists?
        purchase.shipping_fees.create!(
          shipping_type: product.shipping_type,
          amount: product.shipping_fee_amount
        )
      end
    end
    
    status_label = case invoice_status
                   when 0 then "DRAFT"
                   when 1 then "SENT"
                   when 2 then "CONFIRMED"
                   when 3 then "PAID"
                   else "UNKNOWN"
                   end
    puts "  Created invoice and shipping for purchase #{purchase.id} (status: #{status_label}, month: #{purchase_month})"
  end
else
  puts "⚠️  MANNERSOUND products (ID: 7-14) not found. Skipping MANNERSOUND purchase data creation."
end

# クリニック情報を作成（最下部に表示するため最後に作成）
puts "🏥 Creating clinic users at the end..."
clinic_level = levels["クリニック"]
wott_clinic_level = wott_levels["クリニック"]

clinics_data = [
  {
    name: "銀座中央クリニック",
    postal_code: "104-0061",
    address: "東京都中央区銀座７丁目８−８ Isgビル 7F",
    phone: "03-6280-6901",
    email: "ginza-central-clinic@example.com"
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
    phone: generate_unique_phone(clinic_data[:phone], used_phones),
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

puts "✅ Created #{clinics_data.length} clinic users at the end (displayed at bottom of hierarchy)"

# すべてのユーザーに対して初期レベル履歴を作成
puts "📋 Creating initial user level histories..."

User.find_each do |user|
  if user.user_level_histories.empty?
    # 初期履歴を作成
    user.user_level_histories.create!(
      level_id: user.level_id,
      previous_level_id: nil,
      wott_level_id: user.wott_level_id,
      previous_wott_level_id: nil,
      effective_from: user.created_at || Time.current,
      change_reason: "初期レベル設定",
      changed_by_id: 1  # アジアビジネストラストのID
    )
  else
    # 既存の履歴にWOTTレベルを追加（wott_level_idがnilの場合のみ）
    user.user_level_histories.where(wott_level_id: nil).update_all(
      wott_level_id: user.wott_level_id,
      previous_wott_level_id: user.wott_level_id
    )
  end
end

puts "✅ Created initial user level histories for all users"

# 最終チェック：請求書がない購入に対して請求書を作成
puts "🔍 Final check: Creating invoices for purchases without invoice..."
purchases_without_invoice = Purchase.includes(:purchase_invoice).where(purchase_invoice: { id: nil })
if purchases_without_invoice.any?
  puts "  Found #{purchases_without_invoice.count} purchases without invoice"
  purchases_without_invoice.each do |purchase|
    invoice_number = PurchaseInvoice.generate_invoice_number
    purchase_month = purchase.purchased_at.strftime("%Y-%m")
    
    # 9月・10月の購入は支払済み（status: 3）、11月は購入ステータスに応じて設定
    if purchase_month == "2025-09" || purchase_month == "2025-10"
      invoice_status = 3  # PAID
      invoice_sent_at = purchase.purchased_at
    else
      invoice_status = case purchase.status
                       when 'built' then 0
                       when 'reserved' then 1
                       when 'paid' then 2
                       else 0
                       end
      invoice_sent_at = purchase.status == 'built' ? nil : purchase.purchased_at
    end
    
    purchase.create_purchase_invoice!(
      invoice_number: invoice_number,
      invoice_date: purchase.purchased_at.to_date,
      due_date: purchase.purchased_at.to_date + 1.week,
      total_amount: purchase.total_price,
      status: invoice_status,
      sent_at: invoice_sent_at,
      confirmed_at: (invoice_status == 2 || invoice_status == 3 ? purchase.purchased_at : nil)
    )
    
    # 送料を設定
    unless purchase.shipping_fees.exists?
      purchase.purchase_items.includes(:product).each do |item|
        product = item.product
        unless purchase.shipping_fees.where(shipping_type: product.shipping_type).exists?
          purchase.shipping_fees.create!(
            shipping_type: product.shipping_type,
            amount: product.shipping_fee_amount
          )
        end
      end
    end
    
    puts "  Created invoice #{invoice_number} for purchase #{purchase.id} (month: #{purchase_month})"
  end
  puts "✅ Created #{purchases_without_invoice.count} missing invoices"
else
  puts "  All purchases have invoices"
end

puts "✅ Set shipping fees for all purchases"

# 11月分の全ての購入データのステータスを'paid'に更新し、請求書ステータスも3（PAID）に更新
puts "💳 Updating November purchases to paid status..."
november_purchases = Purchase.where('purchased_at >= ? AND purchased_at < ?', '2025-11-01', '2025-12-01')
november_purchases.each do |purchase|
  purchase.update!(status: 'paid', payment_type: 'cash')
  
  # 請求書のステータスも更新
  if purchase.purchase_invoice
    purchase.purchase_invoice.update!(
      status: 3,  # PAID
      sent_at: purchase.purchased_at,
      confirmed_at: purchase.purchased_at
    )
  end
end
puts "✅ Updated #{november_purchases.count} purchases (November) to paid status (cash payment) with invoice status 3 (PAID)"

puts "✅ Seeding completed!"
