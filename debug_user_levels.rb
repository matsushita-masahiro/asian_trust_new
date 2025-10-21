#!/usr/bin/env ruby

# Rails環境を読み込み
require_relative 'config/environment'

puts "=== ユーザーレベル確認 ==="

# 松本優子の直下ユーザーを確認
matsumoto = User.find_by(name: "松本優子")
if matsumoto
  puts "松本優子 (ID: #{matsumoto.id})"
  puts "レベル: #{matsumoto.level}"
  puts "レベルID: #{matsumoto.level&.id}"
  puts "レベル値(value): #{matsumoto.level&.value}"
  puts "レベル名: #{matsumoto.level&.name}"
  puts ""
  
  puts "直下ユーザー:"
  matsumoto.referrals.each do |referral|
    puts "- #{referral.name}"
    puts "  レベル: #{referral.level}"
    puts "  レベルID: #{referral.level&.id}"
    puts "  レベル値(value): #{referral.level&.value}"
    puts "  レベル名: #{referral.level&.name}"
    puts "  level.value.in?([4, 5, 6]): #{referral.level&.value&.in?([4, 5, 6])}"
    puts ""
  end
else
  puts "松本優子が見つかりません"
end

puts "=== 全レベル一覧 ==="
Level.all.each do |level|
  puts "ID: #{level.id}, 名前: #{level.name}, 値: #{level.value}, シンボル: #{level.symbol}"
end