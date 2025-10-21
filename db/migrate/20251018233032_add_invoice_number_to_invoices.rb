class AddInvoiceNumberToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :invoice_number, :string
  end
end
