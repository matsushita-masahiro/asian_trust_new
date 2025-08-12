class MigrateExistingUsersToLevelHistory < ActiveRecord::Migration[8.0]
  def up
    # 既存の全ユーザーに対して初期履歴レコードを作成
    User.find_each do |user|
      next if user.user_level_histories.exists?
      
      # システムユーザー（ID=1）を変更者として設定、存在しない場合は最初の管理者を使用
      system_user = User.find_by(id: 1) || User.where(admin: true).first || user
      
      user.user_level_histories.create!(
        level_id: user.level_id,
        previous_level_id: nil,
        effective_from: user.created_at || Time.current,
        effective_to: nil,
        change_reason: 'システム移行時の初期レベル設定',
        changed_by: system_user,
        ip_address: '127.0.0.1'
      )
    end
    
    puts "✅ #{User.count}人のユーザーに初期レベル履歴を作成しました"
  end

  def down
    # ロールバック時は移行で作成した履歴レコードを削除
    UserLevelHistory.where(change_reason: 'システム移行時の初期レベル設定').delete_all
    puts "✅ 移行で作成したレベル履歴を削除しました"
  end
end
