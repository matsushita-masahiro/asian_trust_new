# 既存ユーザーの初期レベル履歴を作成

puts "=== 既存ユーザーの初期レベル履歴作成 ==="

# レベル履歴が存在しないユーザーを取得
users_without_history = User.left_joins(:user_level_histories)
                           .where(user_level_histories: { id: nil })
                           .where.not(level_id: nil)

puts "履歴が存在しないユーザー数: #{users_without_history.count}"

if users_without_history.empty?
  puts "全ユーザーに履歴が存在します。"
  exit
end

# 各ユーザーの初期履歴を作成
users_without_history.find_each do |user|
  puts "ユーザー #{user.display_name} (ID: #{user.id}) の履歴を作成中..."
  
  begin
    UserLevelHistory.create!(
      user: user,
      level_id: user.level_id,
      previous_level_id: nil,
      effective_from: user.created_at,
      effective_to: nil,
      change_reason: "初期レベル設定（システム移行時）",
      changed_by_id: 1  # 管理者のIDを指定（適切なIDに変更してください）
    )
    puts "  ✅ 作成完了"
  rescue => e
    puts "  ❌ エラー: #{e.message}"
  end
end

puts "\n=== 履歴作成完了 ==="

# アドバイザー5-1の履歴を確認
advisor = User.find_by(id: 5)
if advisor
  puts "\nアドバイザー5-1の履歴:"
  advisor.user_level_histories.by_effective_date.each do |history|
    puts "  レベル: #{history.level.name}, 有効開始: #{history.effective_from}"
  end
end