#!/usr/bin/env ruby
require_relative 'config/environment'

puts "🔍 Checking user hierarchy structure..."

# 総代理店レベルのユーザーを取得
tokuyaku_users = User.joins(:level).where(levels: { name: "総代理店" })

puts "\n👥 総代理店ユーザー: #{tokuyaku_users.count}名"
tokuyaku_users.each do |user|
  puts "\n📋 #{user.name} (ID: #{user.id})"
  
  # 直下の代理店を取得
  agents = user.referrals.joins(:level).where(levels: { name: "代理店" })
  puts "  └─ 代理店: #{agents.count}名"
  agents.each do |agent|
    puts "    ├─ #{agent.name}"
    
    # 代理店の直下のアドバイザーを取得
    advisors = agent.referrals.joins(:level).where(levels: { name: "アドバイザー" })
    puts "      └─ アドバイザー: #{advisors.count}名"
    advisors.each do |advisor|
      puts "        ├─ #{advisor.name}"
    end
  end
end

puts "\n📊 Summary:"
puts "総代理店: #{User.joins(:level).where(levels: { name: "総代理店" }).count}名"
puts "代理店: #{User.joins(:level).where(levels: { name: "代理店" }).count}名"
puts "アドバイザー: #{User.joins(:level).where(levels: { name: "アドバイザー" }).count}名"
puts "サロン: #{User.joins(:level).where(levels: { name: "サロン" }).count}名"
puts "クリニック: #{User.joins(:level).where(levels: { name: "クリニック" }).count}名"
puts "お客様: #{User.joins(:level).where(levels: { name: "お客様" }).count}名"