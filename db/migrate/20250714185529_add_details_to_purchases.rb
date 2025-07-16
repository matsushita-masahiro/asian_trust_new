class AddDetailsToPurchases < ActiveRecord::Migration[8.0]
  def change
    add_column :purchases, :customer_id, :integer
    add_column :purchases, :quantity, :integer
    add_column :purchases, :unit_price, :integer
    # db/migrate/XXXX_add_details_to_purchases.rb
    add_index :purchases, :customer_id
    add_foreign_key :purchases, :customers

  end
end
