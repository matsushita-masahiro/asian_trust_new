class CreatePurchaseInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_invoices do |t|
      t.references :purchase, null: false, foreign_key: true
      t.string :invoice_number
      t.date :invoice_date
      t.date :due_date
      t.decimal :total_amount
      t.integer :status
      t.datetime :sent_at
      t.datetime :confirmed_at
      t.datetime :receipt_requested_at
      t.datetime :receipt_sent_at
      t.text :notes

      t.timestamps
    end
  end
end
