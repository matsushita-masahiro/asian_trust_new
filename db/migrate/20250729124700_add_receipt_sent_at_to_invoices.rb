class AddReceiptSentAtToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :receipt_sent_at, :datetime
  end
end
