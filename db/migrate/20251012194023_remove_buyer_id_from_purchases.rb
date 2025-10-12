class RemoveBuyerIdFromPurchases < ActiveRecord::Migration[8.0]
  def change
    remove_column :purchases, :buyer_id, :integer
  end
end
