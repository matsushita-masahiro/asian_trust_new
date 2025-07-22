class CreateAccessLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :access_logs do |t|
      t.string :ip_address
      t.string :path
      t.string :user_agent
      t.references :user, null: true, foreign_key: true # ゲストユーザーも記録するためnull許可
      t.datetime :accessed_at

      t.timestamps
    end
    
    add_index :access_logs, :accessed_at
    add_index :access_logs, [:path, :accessed_at]
  end
end
