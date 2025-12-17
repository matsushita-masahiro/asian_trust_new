# クリニックデータのフィクスチャ
# 各クリニック用のユーザーを作成し、アジアビジネストラストの直下に配置

# アジアビジネストラストユーザーを取得
asia_trust_user = User.find_by(id: 1)
unless asia_trust_user
  puts "❌ アジアビジネストラストユーザー（ID: 1）が見つかりません"
  exit
end

puts "✅ アジアビジネストラストユーザー確認: #{asia_trust_user.name}"

# クリニックユーザーに住所を登録する処理
def create_clinic_address(user, postal_code, address)
  # 登録住所を作成
  registration_address = user.addresses.find_or_create_by(address_type: 'registration') do |addr|
    addr.postal_code = postal_code
    addr.address = address
  end
  
  if registration_address.persisted?
    puts "  住所登録完了: 〒#{postal_code} #{address}"
  else
    puts "  住所登録失敗: #{registration_address.errors.full_messages}"
  end
end

# 既存のクリニックユーザーの紹介者を更新
puts "\n=== 既存クリニックユーザーの紹介者を更新 ==="
existing_clinic_user_ids = [115, 116, 117]  # 神保町再生医療、森川内科、GINZA中央

existing_clinic_user_ids.each do |user_id|
  user = User.find_by(id: user_id)
  if user
    old_referrer_id = user.referred_by_id
    old_referrer_name = old_referrer_id ? User.find_by(id: old_referrer_id)&.name : 'なし'
    
    puts "更新前: #{user.name} (ID: #{user.id}) - 紹介者: #{old_referrer_name}"
    
    user.update!(referred_by_id: asia_trust_user.id)
    puts "更新後: #{user.name} (ID: #{user.id}) - 紹介者: #{asia_trust_user.name}"
    
    # 既存クリニックユーザーにも住所を登録
    case user.name
    when 'GINZA中央クリニック'
      create_clinic_address(user, '1040061', '東京都中央区銀座4丁目6-1 銀座医科ビル3階')
    when '神保町再生医療クリニック'
      create_clinic_address(user, '1010051', '東京都千代田区神田神保町1-1-1')
    when '森川内科クリニック'
      create_clinic_address(user, '1500001', '東京都渋谷区神宮前2-2-2')
    end
  else
    puts "ユーザーID #{user_id} が見つかりません"
  end
end

# クリニックレベルを取得または作成
clinic_level = Level.find_or_create_by(name: 'クリニック', value: 6)

# 1. GINZA中央クリニック
ginza_user = User.find_or_create_by(email: 'ginza-central@asia-b-t.com') do |user|
  user.name = 'GINZA中央クリニック'
  user.level = clinic_level
  user.phone = '03-1111-1111'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.referred_by_id = asia_trust_user.id  # アジアビジネストラストの直下に配置
end

ginza_clinic = Clinic.find_or_create_by(user: ginza_user) do |clinic|
  clinic.name = 'GINZA中央クリニック'
  clinic.is_active = true
  clinic.holiday_closure_enabled = true
end

if ginza_user.persisted? && ginza_clinic.persisted?
  # GINZA中央クリニックの営業時間設定
  # 診療時間: 10:00～18:30 ※昼休憩13:00～15:00 ※日曜お休み
  [1, 2, 3, 4, 5, 6].each do |weekday| # 月～土
    ClinicBusinessHour.find_or_create_by(clinic: ginza_clinic, weekday: weekday) do |hour|
      hour.start_time = '10:00'
      hour.end_time = '18:30'
    end
  end

  # GINZA中央クリニックの休憩時間設定
  [1, 2, 3, 4, 5, 6].each do |weekday| # 月～土
    ClinicBreakTime.find_or_create_by(clinic: ginza_clinic, weekday: weekday) do |break_time|
      break_time.start_time = '13:00'
      break_time.end_time = '15:00'
    end
  end

  # GINZA中央クリニックの休診日設定（日曜日）
  ClinicHoliday.find_or_create_by(clinic: ginza_clinic, weekday: 0) do |holiday|
    holiday.reason = '定休日'
  end

  # GINZA中央クリニックの住所を登録
  create_clinic_address(ginza_user, '1040061', '東京都中央区銀座4丁目6-1 銀座医科ビル3階')
  
  puts "✅ GINZA中央クリニック作成完了 (ID: #{ginza_clinic.id})"
else
  puts "❌ GINZA中央クリニック作成失敗"
  puts "  User errors: #{ginza_user.errors.full_messages}" unless ginza_user.persisted?
  puts "  Clinic errors: #{ginza_clinic.errors.full_messages}" unless ginza_clinic.persisted?
end

# 2. 神保町再生医療クリニック
jinbocho_user = User.find_or_create_by(email: 'jinbocho-regenerative@asia-b-t.com') do |user|
  user.name = '神保町再生医療クリニック'
  user.level = clinic_level
  user.phone = '03-2222-2222'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.referred_by_id = asia_trust_user.id  # アジアビジネストラストの直下に配置
end

jinbocho_clinic = Clinic.find_or_create_by(user: jinbocho_user) do |clinic|
  clinic.name = '神保町再生医療クリニック'
  clinic.is_active = true
  clinic.holiday_closure_enabled = true
end

if jinbocho_user.persisted? && jinbocho_clinic.persisted?
  # 神保町再生医療クリニックの営業時間設定
  # 診療日&時間: 火、水、金、土の12時から19時
  [2, 3, 5, 6].each do |weekday| # 火、水、金、土
    ClinicBusinessHour.find_or_create_by(clinic: jinbocho_clinic, weekday: weekday) do |hour|
      hour.start_time = '12:00'
      hour.end_time = '19:00'
    end
  end

  # 神保町再生医療クリニックの住所を登録
  create_clinic_address(jinbocho_user, '1010051', '東京都千代田区神田神保町1-1-1')
  
  puts "✅ 神保町再生医療クリニック作成完了 (ID: #{jinbocho_clinic.id})"
else
  puts "❌ 神保町再生医療クリニック作成失敗"
  puts "  User errors: #{jinbocho_user.errors.full_messages}" unless jinbocho_user.persisted?
  puts "  Clinic errors: #{jinbocho_clinic.errors.full_messages}" unless jinbocho_clinic.persisted?
end

# 3. 森川内科クリニック
morikawa_user = User.find_or_create_by(email: 'morikawa-internal@asia-b-t.com') do |user|
  user.name = '森川内科クリニック'
  user.level = clinic_level
  user.phone = '03-3333-3333'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.referred_by_id = asia_trust_user.id  # アジアビジネストラストの直下に配置
end

morikawa_clinic = Clinic.find_or_create_by(user: morikawa_user) do |clinic|
  clinic.name = '森川内科クリニック'
  clinic.is_active = true
  clinic.holiday_closure_enabled = true
end

if morikawa_user.persisted? && morikawa_clinic.persisted?
  # 森川内科クリニックの営業時間設定
  # 月火: 9:00～19:00（休憩時間で12:00-16:00を設定）
  [1, 2].each do |weekday| # 月、火
    ClinicBusinessHour.find_or_create_by(clinic: morikawa_clinic, weekday: weekday) do |hour|
      hour.start_time = '09:00'
      hour.end_time = '19:00'
    end
  end

  # 木金: 9:00～20:00（休憩時間で12:00-16:00を設定）
  [4, 5].each do |weekday| # 木、金
    ClinicBusinessHour.find_or_create_by(clinic: morikawa_clinic, weekday: weekday) do |hour|
      hour.start_time = '09:00'
      hour.end_time = '20:00'
    end
  end

  # 土: 9:00～12:00（午後は休診）
  ClinicBusinessHour.find_or_create_by(clinic: morikawa_clinic, weekday: 6) do |hour|
    hour.start_time = '09:00'
    hour.end_time = '12:00'
  end

  # 日: 10:00～13:00（午後は休診）
  ClinicBusinessHour.find_or_create_by(clinic: morikawa_clinic, weekday: 0) do |hour|
    hour.start_time = '10:00'
    hour.end_time = '13:00'
  end

  # 森川内科クリニックの休憩時間設定
  # 月火木金の12:00-16:00を休憩時間として設定
  [1, 2, 4, 5].each do |weekday|
    ClinicBreakTime.find_or_create_by(clinic: morikawa_clinic, weekday: weekday) do |break_time|
      break_time.start_time = '12:00'
      break_time.end_time = '16:00'
    end
  end

  # 森川内科クリニックの休診日設定
  # 休診日: 水曜・祝日（土曜日午後・日曜日午後は営業時間で制御）
  ClinicHoliday.find_or_create_by(clinic: morikawa_clinic, weekday: 3) do |holiday|
    holiday.reason = '定休日（水曜）'
  end

  # 森川内科クリニックの住所を登録
  create_clinic_address(morikawa_user, '1500001', '東京都渋谷区神宮前2-2-2')
  
  puts "✅ 森川内科クリニック作成完了 (ID: #{morikawa_clinic.id})"
else
  puts "❌ 森川内科クリニック作成失敗"
  puts "  User errors: #{morikawa_user.errors.full_messages}" unless morikawa_user.persisted?
  puts "  Clinic errors: #{morikawa_clinic.errors.full_messages}" unless morikawa_clinic.persisted?
end

# 4. ティファクリニック横浜院
tifa_yokohama_user = User.find_or_create_by(email: 'tifa-yokohama@asia-b-t.com') do |user|
  user.name = 'ティファクリニック横浜院'
  user.level = clinic_level
  user.phone = '045-4444-4444'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.referred_by_id = asia_trust_user.id  # アジアビジネストラストの直下に配置
end

tifa_yokohama_clinic = Clinic.find_or_create_by(user: tifa_yokohama_user) do |clinic|
  clinic.name = 'ティファクリニック横浜院'
  clinic.is_active = true
  clinic.holiday_closure_enabled = true
end

if tifa_yokohama_user.persisted? && tifa_yokohama_clinic.persisted?
  # ティファクリニック横浜院の営業時間設定
  # 月曜日から木曜日まで 10時30分から19時最終受付18時30分
  [1, 2, 3, 4].each do |weekday| # 月～木
    ClinicBusinessHour.find_or_create_by(clinic: tifa_yokohama_clinic, weekday: weekday) do |hour|
      hour.start_time = '10:30'
      hour.end_time = '19:00'
    end
  end

  # ティファクリニック横浜院の休診日設定（金土日）
  [5, 6, 0].each do |weekday|
    ClinicHoliday.find_or_create_by(clinic: tifa_yokohama_clinic, weekday: weekday) do |holiday|
      holiday.reason = '定休日'
    end
  end

  # ティファクリニック横浜院の住所を登録
  create_clinic_address(tifa_yokohama_user, '2200004', '神奈川県横浜市西区北幸1-1-1')
  
  puts "✅ ティファクリニック横浜院作成完了 (ID: #{tifa_yokohama_clinic.id})"
else
  puts "❌ ティファクリニック横浜院作成失敗"
  puts "  User errors: #{tifa_yokohama_user.errors.full_messages}" unless tifa_yokohama_user.persisted?
  puts "  Clinic errors: #{tifa_yokohama_clinic.errors.full_messages}" unless tifa_yokohama_clinic.persisted?
end

# 5. ティファクリニック新宿東口院
tifa_shinjuku_user = User.find_or_create_by(email: 'tifa-shinjuku-east@asia-b-t.com') do |user|
  user.name = 'ティファクリニック新宿東口院'
  user.level = clinic_level
  user.phone = '03-5555-5555'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.referred_by_id = asia_trust_user.id  # アジアビジネストラストの直下に配置
end

tifa_shinjuku_clinic = Clinic.find_or_create_by(user: tifa_shinjuku_user) do |clinic|
  clinic.name = 'ティファクリニック新宿東口院'
  clinic.is_active = true
  clinic.holiday_closure_enabled = true
end

if tifa_shinjuku_user.persisted? && tifa_shinjuku_clinic.persisted?
  # ティファクリニック新宿東口院の営業時間設定
  # 10時から19時最終受付17時半 ※定休日月曜日木曜日です
  [2, 3, 5, 6, 0].each do |weekday| # 火、水、金、土、日
    ClinicBusinessHour.find_or_create_by(clinic: tifa_shinjuku_clinic, weekday: weekday) do |hour|
      hour.start_time = '10:00'
      hour.end_time = '19:00'
    end
  end

  # ティファクリニック新宿東口院の休診日設定（月曜・木曜）
  [1, 4].each do |weekday|
    ClinicHoliday.find_or_create_by(clinic: tifa_shinjuku_clinic, weekday: weekday) do |holiday|
      holiday.reason = '定休日'
    end
  end

  # ティファクリニック新宿東口院の住所を登録
  create_clinic_address(tifa_shinjuku_user, '1600022', '東京都新宿区新宿3-1-1')
  
  puts "✅ ティファクリニック新宿東口院作成完了 (ID: #{tifa_shinjuku_clinic.id})"
else
  puts "❌ ティファクリニック新宿東口院作成失敗"
  puts "  User errors: #{tifa_shinjuku_user.errors.full_messages}" unless tifa_shinjuku_user.persisted?
  puts "  Clinic errors: #{tifa_shinjuku_clinic.errors.full_messages}" unless tifa_shinjuku_clinic.persisted?
end

puts "\n🎉 クリニックデータの作成処理が完了しました！"
puts "\n=== 全クリニック一覧（紹介者更新後） ==="
Clinic.all.order(:id).each do |clinic|
  referrer = clinic.user.referred_by_id ? User.find_by(id: clinic.user.referred_by_id)&.name : 'なし'
  puts "- #{clinic.name} (ID: #{clinic.id}, User: #{clinic.user.name} [ID: #{clinic.user.id}], 紹介者: #{referrer})"
end