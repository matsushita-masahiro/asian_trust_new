# descendant_idsメソッドの動作確認

puts "=== descendant_ids メソッドの確認 ==="

advisor = User.find(5)
puts "ユーザー: #{advisor.display_name} (ID: #{advisor.id})"

descendant_ids = advisor.descendant_ids
puts "descendant_ids: #{descendant_ids}"
puts "自分自身が含まれているか: #{descendant_ids.include?(advisor.id)}"

# descendantsメソッドの確認
descendants = advisor.descendants
puts "descendants: #{descendants.pluck(:id)}"
puts "descendants数: #{descendants.count}"

# referralsの確認
referrals = advisor.referrals
puts "referrals: #{referrals.pluck(:id)}"
puts "referrals数: #{referrals.count}"

# 階層構造の確認
puts "\n=== 階層構造 ==="
def show_tree(user, level = 0)
  indent = "  " * level
  puts "#{indent}#{user.display_name} (ID: #{user.id})"
  user.referrals.each do |child|
    show_tree(child, level + 1)
  end
end

show_tree(advisor)