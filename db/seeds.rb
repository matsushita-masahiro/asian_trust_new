puts "🔄 Seeding started......"

adapter = ActiveRecord::Base.connection.adapter_name

# SQLite環境のみ、外部キー制約を一時無効化
if adapter == "SQLite"
  ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF")
  User.delete_all
  ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='users'")
  ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON")
else
  # PostgreSQL など他の環境では普通に削除
  User.delete_all
end

user_id_seq = 1
lstep_id_seq = 1

# Levelデータを取得（nameで検索）
levels = Level.all.index_by(&:name)

# 最上位
company = User.create!(
  id: user_id_seq,
  name: "アジアビジネストラスト",
  email: "info@abt-saisei.com",
  password: "password",
  level_id: levels["アジアビジネストラスト"].id,
  lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
  confirmed_at: Time.current
)
user_id_seq += 1
lstep_id_seq += 1

# 特約代理店（level: 特約代理店）
special_agents = 3.times.map do |i|
  user = User.create!(
    id: user_id_seq,
    name: "特約代理店#{i + 1}",
    email: "special_agent#{i + 1}@example.com",
    password: "password",
    level_id: levels["特約代理店"].id,
    referred_by_id: company.id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1
  user
end

# 代理店
agents = []
special_agents.each_with_index do |parent, i|
  2.times do |j|
    user = User.create!(
      id: user_id_seq,
      name: "代理店#{i + 1}-#{j + 1}",
      email: "agent#{i + 1}-#{j + 1}@example.com",
      password: "password",
      level_id: levels["代理店"].id,
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
advisors = []
agents.each_with_index do |parent, i|
  2.times do |j|
    user = User.create!(
      id: user_id_seq,
      name: "アドバイザー#{i + 1}-#{j + 1}",
      email: "advisor#{i + 1}-#{j + 1}@example.com",
      password: "password",
      level_id: levels["アドバイザー"].id,
      referred_by_id: parent.id,
      lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
      confirmed_at: Time.current
    )
    user_id_seq += 1
    lstep_id_seq += 1
    advisors << user
  end
end

# サロン・病院
advisors.each_with_index do |parent, i|
  ["サロン", "病院"].each_with_index do |type, _idx|
    User.create!(
      id: user_id_seq,
      name: "#{type}#{i + 1}",
      email: "#{type.downcase}#{i + 1}@example.com",
      password: "password",
      level_id: levels[type].id,
      referred_by_id: parent.id,
      lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
      confirmed_at: Time.current
    )
    user_id_seq += 1
    lstep_id_seq += 1
  end
end

# --- 追加パターン (1) ---
2.times do |i|
  advisor = User.create!(
    id: user_id_seq,
    name: "特約1-アドバイザー#{i + 1}",
    email: "tokuyaku1_advisor#{i + 1}@example.com",
    password: "password",
    level_id: levels["アドバイザー"].id,
    referred_by_id: special_agents[0].id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1

  User.create!(
    id: user_id_seq,
    name: "特約1-サロン#{i + 1}",
    email: "tokuyaku1_salon#{i + 1}@example.com",
    password: "password",
    level_id: levels["サロン"].id,
    referred_by_id: advisor.id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1
end

# --- 追加パターン (2) ---
2.times do |i|
  User.create!(
    id: user_id_seq,
    name: "特約2-サロン#{i + 1}",
    email: "tokuyaku2_salon#{i + 1}@example.com",
    password: "password",
    level_id: levels["サロン"].id,
    referred_by_id: special_agents[1].id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1
end

# --- 追加パターン (3) ---
2.times do |i|
  advisor1 = User.create!(
    id: user_id_seq,
    name: "特約3-アドバイザー#{i + 1}-1",
    email: "tokuyaku3_advisor#{i + 1}_1@example.com",
    password: "password",
    level_id: levels["アドバイザー"].id,
    referred_by_id: special_agents[2].id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1

  advisor2 = User.create!(
    id: user_id_seq,
    name: "特約3-アドバイザー#{i + 1}-2",
    email: "tokuyaku3_advisor#{i + 1}_2@example.com",
    password: "password",
    level_id: levels["アドバイザー"].id,
    referred_by_id: advisor1.id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1

  User.create!(
    id: user_id_seq,
    name: "特約3-サロン#{i + 1}",
    email: "tokuyaku3_salon#{i + 1}@example.com",
    password: "password",
    level_id: levels["サロン"].id,
    referred_by_id: advisor2.id,
    lstep_user_id: "lstep_#{format('%04d', lstep_id_seq)}",
    confirmed_at: Time.current
  )
  user_id_seq += 1
  lstep_id_seq += 1
end

puts "✅ Seeding completed!"
