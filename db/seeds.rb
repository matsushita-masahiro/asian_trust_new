puts "🔄 Seeding started..."

User.destroy_all

# ID=1: アジアビジネストラスト（最上位）
company = User.create!(
  id: 1,
  name: "アジアビジネストラスト",
  email: "company@example.com",
  password: "password",
  level: 0,  # company
  confirmed_at: Time.current
)

# 特約代理店（level: 1）
special_agents = 3.times.map do |i|
  User.create!(
    name: "特約代理店#{i + 1}",
    email: "special_agent#{i + 1}@example.com",
    password: "password",
    level: 1,
    referred_by_id: company.id,
    confirmed_at: Time.current
  )
end

# 各特約代理店の配下に代理店（level: 2）
agents = []
special_agents.each_with_index do |parent, i|
  2.times do |j|
    agents << User.create!(
      name: "代理店#{i + 1}-#{j + 1}",
      email: "agent#{i + 1}-#{j + 1}@example.com",
      password: "password",
      level: 2,
      referred_by_id: parent.id,
      confirmed_at: Time.current
    )
  end
end

# 各代理店の配下にアドバイザー（level: 3）
advisors = []
agents.each_with_index do |parent, i|
  2.times do |j|
    advisors << User.create!(
      name: "アドバイザー#{i + 1}-#{j + 1}",
      email: "advisor#{i + 1}-#{j + 1}@example.com",
      password: "password",
      level: 3,
      referred_by_id: parent.id,
      confirmed_at: Time.current
    )
  end
end

# 各アドバイザーの配下にサロン・病院（level: 4, 5）
advisors.each_with_index do |parent, i|
  User.create!(
    name: "サロン#{i + 1}",
    email: "salon#{i + 1}@example.com",
    password: "password",
    level: 4,
    referred_by_id: parent.id,
    confirmed_at: Time.current
  )
  User.create!(
    name: "病院#{i + 1}",
    email: "hospital#{i + 1}@example.com",
    password: "password",
    level: 5,
    referred_by_id: parent.id,
    confirmed_at: Time.current
  )
end

puts "✅ Seeding completed!"
