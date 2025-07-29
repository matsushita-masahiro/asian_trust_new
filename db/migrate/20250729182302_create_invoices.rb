class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices, if_not_exists: true do |t|
      t.references :user, null: false, foreign_key: true
      t.references :invoice_recipient, null: false, foreign_key: true

      t.date :invoice_date
      t.date :due_date
      t.integer :total_amount

      t.string :bank_name
      t.string :bank_branch_name
      t.string :bank_account_type
      t.string :bank_account_number
      t.string :bank_account_name
      t.integer :status, default: 0, null: false
      t.text :notes
      t.datetime :sent_at
      t.timestamps
    end
  end
end
