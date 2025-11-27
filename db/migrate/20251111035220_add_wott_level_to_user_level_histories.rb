class AddWottLevelToUserLevelHistories < ActiveRecord::Migration[8.0]
  def change
    add_column :user_level_histories, :wott_level_id, :integer
    add_column :user_level_histories, :previous_wott_level_id, :integer
    
    add_index :user_level_histories, :wott_level_id
    add_index :user_level_histories, :previous_wott_level_id
    
    add_foreign_key :user_level_histories, :wott_levels, column: :wott_level_id
    add_foreign_key :user_level_histories, :wott_levels, column: :previous_wott_level_id
  end
end
