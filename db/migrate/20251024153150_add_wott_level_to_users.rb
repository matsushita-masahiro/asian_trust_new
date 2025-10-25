class AddWottLevelToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :wott_level, null: true, foreign_key: true
  end
end
