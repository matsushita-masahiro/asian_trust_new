class AddBuyerIdToPurchases < ActiveRecord::Migration[8.0]
  def change
    add_column :purchases, :buyer_id, :integer
    add_index :purchases, :buyer_id
    add_index :purchases, [:user_id, :buyer_id]
    add_foreign_key :purchases, :users, column: :buyer_id
  end
end
