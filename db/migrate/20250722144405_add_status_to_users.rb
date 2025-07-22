class AddStatusToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :status, :string, default: 'active', null: false
    add_index :users, :status
  end
end
