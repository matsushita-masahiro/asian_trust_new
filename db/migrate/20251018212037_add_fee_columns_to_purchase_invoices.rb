class AddFeeColumnsToPurchaseInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :purchase_invoices, :shipping_fee, :integer, default: 0
    add_column :purchase_invoices, :admin_fee, :integer, default: 0
    add_column :purchase_invoices, :tax_amount, :integer, default: 0
    add_column :purchase_invoices, :tax_rate, :decimal, precision: 5, scale: 4, default: 0.1
    add_column :purchase_invoices, :subtotal_before_tax, :integer, default: 0
    add_column :purchase_invoices, :total_with_tax, :integer, default: 0
  end
end
