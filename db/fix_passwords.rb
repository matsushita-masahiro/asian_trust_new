# Heroku上でパスワードがnilになったユーザーを修正するスクリプト
# 実行方法: heroku run rails runner db/fix_passwords.rb

puts "🔧 パスワードがnilのユーザーを修正中..."

# パスワードがnilまたは空のユーザーを取得
users_without_password = User.where(encrypted_password: [nil, ''])

puts "修正対象のユーザー: #{users_without_password.count}件"

if users_without_password.any?
  users_without_password.each do |user|
    # パスワードを設定（バリデーションをスキップ）
    user.password = "password123"
    user.password_confirmation = "password123"
    
    # バリデーションをスキップして保存
    if user.save(validate: false)
      puts "✓ #{user.name} (ID: #{user.id}) のパスワードを修正しました"
    else
      puts "❌ #{user.name} (ID: #{user.id}) の修正に失敗しました: #{user.errors.full_messages.join(', ')}"
    end
  end
  
  puts "\n✅ パスワード修正完了！"
  puts "修正されたユーザー数: #{users_without_password.count}件"
else
  puts "✅ 修正が必要なユーザーはありません"
end

# 修正後の確認
puts "\n📊 修正後の状況:"
total_users = User.count
users_with_password = User.where.not(encrypted_password: [nil, '']).count
users_without_password = User.where(encrypted_password: [nil, '']).count

puts "総ユーザー数: #{total_users}"
puts "パスワード設定済み: #{users_with_password}"
puts "パスワード未設定: #{users_without_password}"

if users_without_password == 0
  puts "🎉 全てのユーザーにパスワードが設定されました！"
else
  puts "⚠️  まだ#{users_without_password}名のユーザーにパスワードが設定されていません"
end