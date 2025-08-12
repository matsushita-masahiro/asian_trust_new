# アドバイザー5-1の子孫関係を確認

puts "=== アドバイザー5-1 子孫関係確認 ==="

advisor = User.find(5)
puts "ユーザー: #{advisor.display_name} (ID: #{advisor.id})"

# descendant_idsメソッドの結果を確認
descendant_ids = advisor.descendant_ids
puts "\ndescendant_ids: #{descendant_ids}"
puts "子孫数: #{descendant_ids.count}"

# 自分自身が含まれているかチェック
if descendant_ids.include?(advisor.id)
  puts "⚠️  自分自身(ID: #{advisor.id})が子孫に含まれています！"
  puts "これが重複計算の原因です。"
else
  puts "✅ 自分自身は子孫に含まれていません"
end

# 直接の紹介者を確認
puts "\n=== 直接の紹介者（referrals）==="
referrals = advisor.referrals
puts "直接紹介者数: #{referrals.count}"
referrals.each do |referral|
  puts "  #{referral.display_name} (ID: #{referral.id}, レベル: #{referral.level&.name})"
end

# descendantsメソッドの実装を確認
puts "\n=== descendants メソッドの動作確認 ==="
descendants = advisor.descendants
puts "descendants数: #{descendants.count}"
puts "descendants IDs: #{descendants.pluck(:id)}"

# 階層構造を表示
puts "\n=== 階層構造 ==="
def show_hierarchy(user, level = 0)
  indent = "  " * level
  puts "#{indent}#{user.display_name} (ID: #{user.id}, レベル: #{user.level&.name})"
  
  user.referrals.each do |child|
    show_hierarchy(child, level + 1)
  end
end

show_hierarchy(advisor)