class CreateUserLevelHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :user_level_histories do |t|
      t.references :user, null: false, foreign_key: true
      t.references :level, null: false, foreign_key: true
      t.references :previous_level, null: true, foreign_key: { to_table: :levels }
      t.datetime :effective_from, null: false
      t.datetime :effective_to, null: true
      t.text :change_reason, null: false
      t.references :changed_by, null: false, foreign_key: { to_table: :users }
      t.string :ip_address, limit: 45

      t.timestamps
    end

    # 追加のインデックス（referencesで自動作成されるもの以外）
    add_index :user_level_histories, [:user_id, :effective_from, :effective_to], 
              name: 'idx_user_level_histories_effective_dates'
    add_index :user_level_histories, :created_at
  end
end
