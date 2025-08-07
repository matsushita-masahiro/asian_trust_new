# ボーナス計算用の複雑なテストデータ（アジアビジネストラスト構造）
# 実行方法: rails runner db/seeds_bonus_test.rb

def number_with_delimiter(number)
  number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
end

puts "🚀 ボーナス計算用テストデータの作成を開始します..."

# 既存データをクリア（外部キー制約に配慮した順）
puts "📝 既存のデータを完全削除中..."

begin
  Purchase.delete_all
  AccessLog.delete_all
  Customer.delete_all
  User.delete_all
  puts "✅ データ削除完了（外部キー順に削除）"
rescue => e
  puts "❌ データ削除中にエラーが発生しました: #{e.message}"
  exit
end

# IDシーケンスをリセット（SQLite / PostgreSQL 対応）
adapter = ActiveRecord::Base.connection.adapter_name.downcase
begin
  if adapter.include?("sqlite")
    %w(users customers purchases).each do |table|
      ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='#{table}'")
    end
    puts "✅ IDシーケンスをリセットしました (SQLite)"
  elsif adapter.include?("postgresql")
    %w(users customers purchases).each do |table|
      ActiveRecord::Base.connection.execute("ALTER SEQUENCE #{table}_id_seq RESTART WITH 1")
    end
    puts "✅ IDシーケンスをリセットしました (PostgreSQL)"
  end
rescue => e
  puts "⚠️ IDシーケンスリセット時のエラー: #{e.message}"
end

puts "✅ データベース初期化完了"


# ※ 以下の処理はそのまま保持（元の構造と同じ）


# レベル情報を取得
levels = {
  "アジアビジネストラスト" => Level.find_by(name: "アジアビジネストラスト"),  # level_id: 1, value: 0
  "特約代理店" => Level.find_by(name: "特約代理店"),                      # level_id: 2, value: 1
  "代理店" => Level.find_by(name: "代理店"),                            # level_id: 3, value: 2
  "アドバイザー" => Level.find_by(name: "アドバイザー"),                  # level_id: 4, value: 3
  "サロン" => Level.find_by(name: "サロン"),                            # level_id: 5, value: 4
  "病院" => Level.find_by(name: "病院")                                # level_id: 6, value: 5
}

# 商品情報を取得
product = Product.first
unless product
  puts "❌ 商品データが見つかりません。先にseedsを実行してください。"
  exit
end

puts "📊 使用する商品: #{product.name} (基本価格: ¥#{product.base_price})"

# === アジアビジネストラスト階層構造を作成 ===
puts "\n🏗️  アジアビジネストラスト階層構造を作成中..."

# IDカウンター（ID: 1から開始）
user_id_seq = 1
puts "新しいユーザーIDは#{user_id_seq}から開始します"

# 1. 最上位：アジアビジネストラスト（会社レベル）- ID: 1
asia_business_trust = User.create!(
  id: user_id_seq,
  name: "アジアビジネストラスト",
  email: "company_test_bonus@example.com",
  password: "password",
  password_confirmation: "password",
  level_id: levels["アジアビジネストラスト"].id,  # level_id: 1, value: 0（最上位レベル）
  lstep_user_id: "test_company_001",
  status: 'active',
  admin: true,
  confirmed_at: Time.current
)
user_id_seq += 1

# 2. 第2レベル：3つの特約代理店（アジアビジネストラストの直下）- ID: 2, 3, 4
special_agents = []
3.times do |i|
  special_agent = User.create!(
    id: user_id_seq,
    name: "特約代理店#{i+1}",
    email: "special_agent#{i+1}_test_bonus@example.com",
    password: "password",
    password_confirmation: "password",
    level_id: levels["特約代理店"].id,
    referred_by_id: asia_business_trust.id,
    lstep_user_id: "test_special_#{format('%03d', i+1)}",
    status: 'active',
    confirmed_at: Time.current
  )
  special_agents << special_agent
  user_id_seq += 1
end

# 3. 第3レベル：各特約代理店の下に代理店 - ID: 5-10
agents = []
special_agents.each_with_index do |special_agent, i|
  2.times do |j|
    agent = User.create!(
      id: user_id_seq,
      name: "代理店#{i+1}-#{j+1}",
      email: "agent#{i+1}_#{j+1}_test_bonus@example.com",
      password: "password",
      level_id: levels["代理店"].id,
      referred_by_id: special_agent.id,
      lstep_user_id: "test_agent_#{i+1}_#{j+1}",
      status: 'active',
      confirmed_at: Time.current
    )
    agents << agent
    user_id_seq += 1
  end
end

# 4. 第4レベル：アドバイザー（ボーナス対象） - ID: 11-22
advisors = []
agents.each_with_index do |agent, i|
  2.times do |j|
    advisor = User.create!(
      id: user_id_seq,
      name: "アドバイザー#{i+1}-#{j+1}",
      email: "advisor#{i+1}_#{j+1}_test_bonus@example.com",
      password: "password",
      level_id: levels["アドバイザー"].id,
      referred_by_id: agent.id,
      lstep_user_id: "test_advisor_#{i+1}_#{j+1}",
      status: 'active',
      confirmed_at: Time.current
    )
    advisors << advisor
    user_id_seq += 1
  end
end

# 5. 複雑な階層構造を作成
salons = []
hospitals = []
sub_advisors = []

# 5-1. 特約代理店の直下にサロン（一部のケース）
special_agents.first(2).each_with_index do |special_agent, i|
  salon = User.create!(
    id: user_id_seq,
    name: "特約直下サロン#{i+1}",
    email: "special_salon#{i+1}_test_bonus@example.com",
    password: "password",
    level_id: levels["サロン"].id,
    referred_by_id: special_agent.id,
    lstep_user_id: "test_special_salon_#{format('%03d', i+1)}",
    status: 'active',
    confirmed_at: Time.current
  )
  salons << salon
  user_id_seq += 1
end

# 5-2. 代理店の直下に病院（一部のケース）
agents.first(3).each_with_index do |agent, i|
  hospital = User.create!(
    id: user_id_seq,
    name: "代理店直下病院#{i+1}",
    email: "agent_hospital#{i+1}_test_bonus@example.com",
    password: "password",
    level_id: levels["病院"].id,
    referred_by_id: agent.id,
    lstep_user_id: "test_agent_hospital_#{format('%03d', i+1)}",
    status: 'active',
    confirmed_at: Time.current
  )
  hospitals << hospital
  user_id_seq += 1
end

# 5-3. アドバイザーの直下にアドバイザー（一部のケース）
advisors.first(4).each_with_index do |advisor, i|
  sub_advisor = User.create!(
    id: user_id_seq,
    name: "サブアドバイザー#{i+1}",
    email: "sub_advisor#{i+1}_test_bonus@example.com",
    password: "password",
    level_id: levels["アドバイザー"].id,
    referred_by_id: advisor.id,
    lstep_user_id: "test_sub_advisor_#{format('%03d', i+1)}",
    status: 'active',
    confirmed_at: Time.current
  )
  sub_advisors << sub_advisor
  user_id_seq += 1
end

# 5-4. 通常のアドバイザーの下にサロンと病院
advisors.each_with_index do |advisor, i|
  # 各アドバイザーの下にサロンを1つ作成
  salon = User.create!(
    id: user_id_seq,
    name: "サロン#{i+1}",
    email: "salon#{i+1}_test_bonus@example.com",
    password: "password",
    level_id: levels["サロン"].id,
    referred_by_id: advisor.id,
    lstep_user_id: "test_salon_#{format('%03d', i+1)}",
    status: 'active',
    confirmed_at: Time.current
  )
  salons << salon
  user_id_seq += 1
  
  # 各アドバイザーの下に病院を1つ作成
  hospital = User.create!(
    id: user_id_seq,
    name: "病院#{i+1}",
    email: "hospital#{i+1}_test_bonus@example.com",
    password: "password",
    level_id: levels["病院"].id,
    referred_by_id: advisor.id,
    lstep_user_id: "test_hospital_#{format('%03d', i+1)}",
    status: 'active',
    confirmed_at: Time.current
  )
  hospitals << hospital
  user_id_seq += 1
end

# 5-5. サブアドバイザーの下にもサロンと病院
sub_advisors.each_with_index do |sub_advisor, i|
  # サブアドバイザーの下にサロン
  salon = User.create!(
    id: user_id_seq,
    name: "サブサロン#{i+1}",
    email: "sub_salon#{i+1}_test_bonus@example.com",
    password: "password",
    level_id: levels["サロン"].id,
    referred_by_id: sub_advisor.id,
    lstep_user_id: "test_sub_salon_#{format('%03d', i+1)}",
    status: 'active',
    confirmed_at: Time.current
  )
  salons << salon
  user_id_seq += 1
  
  # サブアドバイザーの下に病院
  hospital = User.create!(
    id: user_id_seq,
    name: "サブ病院#{i+1}",
    email: "sub_hospital#{i+1}_test_bonus@example.com",
    password: "password",
    level_id: levels["病院"].id,
    referred_by_id: sub_advisor.id,
    lstep_user_id: "test_sub_hospital_#{format('%03d', i+1)}",
    status: 'active',
    confirmed_at: Time.current
  )
  hospitals << hospital
  user_id_seq += 1
end

# 7. 特殊ケース：停止処分ユーザー - ID: 47
suspended_user = User.create!(
  id: user_id_seq,
  name: "停止処分ユーザー",
  email: "suspended_test_bonus@example.com",
  password: "password",
  level_id: levels["アドバイザー"].id,
  referred_by_id: agents.first.id,
  lstep_user_id: "test_suspended_001",
  status: 'suspended',
  confirmed_at: Time.current
)
user_id_seq += 1

# 8. 特殊ケース：退会ユーザー - ID: 48
inactive_user = User.create!(
  id: user_id_seq,
  name: "退会ユーザー",
  email: "inactive_test_bonus@example.com",
  password: "password",
  level_id: levels["アドバイザー"].id,
  referred_by_id: agents.first.id,
  lstep_user_id: "test_inactive_001",
  status: 'inactive',
  confirmed_at: Time.current
)
user_id_seq += 1

puts "✅ ユーザー階層構造作成完了"
puts "   - アジアビジネストラスト: 1名（最上位）"
puts "   - 特約代理店: #{special_agents.count}名"
puts "   - 代理店: #{agents.count}名"
puts "   - アドバイザー: #{advisors.count}名（通常）+ #{sub_advisors.count}名（サブ）"
puts "   - サロン: #{salons.count}名（特約直下2名、アドバイザー直下#{advisors.count}名、サブアドバイザー直下#{sub_advisors.count}名）"
puts "   - 病院: #{hospitals.count}名（代理店直下3名、アドバイザー直下#{advisors.count}名、サブアドバイザー直下#{sub_advisors.count}名）"
puts "   - 停止処分: 1名"
puts "   - 退会: 1名"
puts "   - 合計: #{user_id_seq - 1}名"

# === 顧客データ作成 ===
puts "\n👥 顧客データを作成中..."

customers = []
20.times do |i|
  customer = Customer.create!(
    name: "テスト顧客#{i+1}",
    email: "customer#{i+1}_test_bonus@example.com",
    phone: "090-1234-#{format('%04d', i+1)}",
    address: "東京都テスト区#{i+1}-#{i+1}-#{i+1}"
  )
  customers << customer
end

# === 複雑な購入パターンを作成 ===
puts "\n💰 複雑な購入パターンを作成中..."

# 今月と先月の日付を設定
current_month = Date.current.beginning_of_month
last_month = current_month - 1.month

purchase_scenarios = [
  # シナリオ1: アジアビジネストラストの直接販売
  {
    user: asia_business_trust,
    customer: customers[0],
    quantity: 50,
    date: current_month + 5.days,
    scenario: "アジアビジネストラストの直接販売"
  },
  
  # シナリオ2: 特約代理店の直接販売
  {
    user: special_agents[0],
    customer: customers[1],
    quantity: 40,
    date: current_month + 7.days,
    scenario: "特約代理店1の直接販売"
  },
  
  # シナリオ3: 代理店の直接販売
  {
    user: agents[0],
    customer: customers[2],
    quantity: 30,
    date: current_month + 10.days,
    scenario: "代理店の直接販売"
  },
  
  # シナリオ4: アドバイザーの直接販売
  {
    user: advisors[0],
    customer: customers[3],
    quantity: 20,
    date: current_month + 15.days,
    scenario: "アドバイザーの直接販売"
  },
  
  # シナリオ5: 無資格者（サロン）の販売 → 上位にボーナス
  {
    user: salons[0],
    customer: customers[4],
    quantity: 40,
    date: current_month + 20.days,
    scenario: "無資格者（サロン）の販売"
  },
  
  # シナリオ6: 無資格者（病院）の販売 → 上位にボーナス
  {
    user: hospitals[0],
    customer: customers[5],
    quantity: 10,
    date: current_month + 25.days,
    scenario: "無資格者（病院）の販売"
  },
  
  # シナリオ7: 複数階層にまたがる販売（階層差額ボーナス）
  {
    user: hospitals[1],
    customer: customers[6],
    quantity: 60,
    date: current_month + 28.days,
    scenario: "深い階層からの販売（複数階層ボーナス）"
  },
  
  # シナリオ8: 先月の販売（月次比較用）
  {
    user: advisors[1],
    customer: customers[7],
    quantity: 30,
    date: last_month + 15.days,
    scenario: "先月のアドバイザー販売"
  },
  
  # シナリオ9: 先月の無資格者販売
  {
    user: salons[1],
    customer: customers[8],
    quantity: 20,
    date: last_month + 20.days,
    scenario: "先月の無資格者販売"
  },
  
  # シナリオ10: 大量購入（高額ボーナステスト）
  {
    user: hospitals[2],
    customer: customers[9],
    quantity: 100,
    date: current_month + 12.days,
    scenario: "大量購入（高額ボーナス）"
  },
  
  # シナリオ11: 停止処分ユーザーの販売（ボーナス対象外）
  {
    user: suspended_user,
    customer: customers[10],
    quantity: 50,
    date: current_month + 8.days,
    scenario: "停止処分ユーザーの販売"
  },
  
  # シナリオ12: 退会ユーザーの販売（ボーナス対象外）
  {
    user: inactive_user,
    customer: customers[11],
    quantity: 30,
    date: current_month + 18.days,
    scenario: "退会ユーザーの販売"
  },
  
  # シナリオ13-20: 複数の小規模販売（統計テスト用）
]

# 追加の小規模販売を生成（10の倍数）
(13..20).each do |i|
  customer_index = i < customers.length ? i : i % customers.length
  purchase_scenarios << {
    user: [advisors, salons, hospitals].flatten.sample,
    customer: customers[customer_index],
    quantity: [10, 20, 30].sample,
    date: current_month + rand(1..30).days,
    scenario: "ランダム小規模販売#{i-12}"
  }
end

# 購入データを作成
purchase_scenarios.each_with_index do |scenario, index|
  purchase = Purchase.create!(
    user: scenario[:user],
    product: product,
    customer: scenario[:customer],
    quantity: scenario[:quantity],
    unit_price: product.base_price,
    price: product.base_price * scenario[:quantity],
    purchased_at: scenario[:date]
  )
  
  puts "   ✓ #{scenario[:scenario]}: #{scenario[:user].name} → ¥#{number_with_delimiter(purchase.price)}"
end

puts "\n📈 ボーナス計算テストケース作成完了！"

# === テスト結果のサマリー表示 ===
puts "\n" + "="*60
puts "🎯 ボーナス計算テストデータ サマリー"
puts "="*60

current_month_str = current_month.strftime("%Y-%m")

puts "\n【階層構造】"
puts "#{asia_business_trust.name} (最上位)"
special_agents.each do |special_agent|
  puts "  └─ #{special_agent.name} (特約代理店)"
  special_agent.referrals.where("email LIKE '%test_bonus%'").each do |agent|
    puts "      └─ #{agent.name} (代理店)"
    agent.referrals.where("email LIKE '%test_bonus%'").each do |advisor|
      puts "          └─ #{advisor.name} (アドバイザー)"
      advisor.referrals.where("email LIKE '%test_bonus%'").each do |salon|
        puts "              └─ #{salon.name} (サロン)"
        salon.referrals.where("email LIKE '%test_bonus%'").each do |hospital|
          puts "                  └─ #{hospital.name} (病院)"
        end
      end
    end
  end
end

puts "\n【今月のボーナス計算結果】"
[asia_business_trust, *special_agents, *agents, *advisors].each do |user|
  bonus = user.bonus_in_month(current_month_str)
  sales = user.own_monthly_sales_total(current_month_str)
  descendant_sales = user.all_descendants_monthly_sales_total(current_month_str)
  
  puts "#{user.name} (#{user.level.name}):"
  puts "  - 自身の売上: ¥#{number_with_delimiter(sales)}"
  puts "  - 下位の売上: ¥#{number_with_delimiter(descendant_sales)}"
  puts "  - 獲得ボーナス: ¥#{number_with_delimiter(bonus)}"
  puts ""
end

# === すべてのユーザーのパスワードを「111111」に強制設定 ===
puts "\n🔐 すべてのユーザーのパスワードを '111111' に設定中..."
User.all.each do |user|
  user.password = "111111"
  user.password_confirmation = "111111"
  user.save!(validate: false)
end
puts "✅ パスワード設定完了！"

puts "\n【テストケース】"
puts "✅ 直接販売ボーナス"
puts "✅ 無資格者販売による上位ボーナス"
puts "✅ 階層差額ボーナス"
puts "✅ 月次比較"
puts "✅ 停止処分・退会ユーザーの除外"
puts "✅ 大量購入・小規模購入"
puts "✅ 複雑な階層構造"

puts "\n🎉 テストデータ作成完了！"
puts "💡 管理画面でボーナス計算結果を確認してください。"

if User.find(1).update(admin: true)
  puts "✅ アジアビジネストラストを管理者にしました"
else
  puts "✅ アジアビジネストラストを管理者にできませんでした"
end