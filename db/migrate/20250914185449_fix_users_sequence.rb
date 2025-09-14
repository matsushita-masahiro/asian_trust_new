class FixUsersSequence < ActiveRecord::Migration[8.0]
  def up
    # PostgreSQLの場合のみシーケンスを修正
    if ActiveRecord::Base.connection.adapter_name.downcase == 'postgresql'
      execute <<-SQL
        SELECT setval('users_id_seq', COALESCE((SELECT MAX(id) FROM users), 1), true);
      SQL
    end
    # SQLiteの場合は何もしない（自動インクリメントが正常に動作する）
  end

  def down
    # ロールバック時は何もしない
  end
end
