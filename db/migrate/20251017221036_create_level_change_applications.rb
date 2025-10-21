class CreateLevelChangeApplications < ActiveRecord::Migration[8.0]
  def change
    create_table :level_change_applications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :current_level, null: false, foreign_key: { to_table: :levels }
      t.references :target_level, null: false, foreign_key: { to_table: :levels }
      t.references :applicant, null: false, foreign_key: { to_table: :users }
      t.text :reason, null: false
      t.string :status, default: 'pending', null: false
      t.date :scheduled_date, null: false
      t.datetime :executed_at
      t.text :error_message
      t.string :ip_address, limit: 45

      t.timestamps
    end

    add_index :level_change_applications, [:status, :scheduled_date], name: 'idx_status_scheduled'
    add_index :level_change_applications, [:user_id, :status], name: 'idx_user_status'
  end
end
