class CreateWottLevelUpgradeRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :wott_level_upgrade_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :current_wott_level_id
      t.integer :requested_wott_level_id
      t.string :status, default: 'pending', null: false
      t.text :admin_notes
      t.integer :processed_by_id
      t.datetime :processed_at
      t.references :purchase, foreign_key: true

      t.timestamps
    end
    
    add_index :wott_level_upgrade_requests, :status
  end
end
