class AddBankInfoToInvoiceBases < ActiveRecord::Migration[8.0]
  def change
    add_column :invoice_bases, :bank_name, :string
    add_column :invoice_bases, :bank_branch_name, :string
    add_column :invoice_bases, :bank_account_type, :string
    add_column :invoice_bases, :bank_account_number, :string
    add_column :invoice_bases, :bank_account_name, :string
  end
end
