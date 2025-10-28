class AddUniqueIndexToUsersPhone < ActiveRecord::Migration[8.0]
  def change
    add_index :users, :phone, unique: true
  end
end