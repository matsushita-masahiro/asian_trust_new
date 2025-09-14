class AddPaymentTypeAndStatusToPurchases < ActiveRecord::Migration[8.0]
  def change
    add_column :purchases, :payment_type, :string, null: false, default: 'cash'
    add_column :purchases, :status, :string, null: false, default: 'built'
    
    add_index :purchases, :payment_type
    add_index :purchases, :status
    add_index :purchases, [:payment_type, :status]
  end
end
