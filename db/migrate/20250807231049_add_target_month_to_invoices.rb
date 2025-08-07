class AddTargetMonthToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :target_month, :string
  end
end
