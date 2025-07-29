class AddRepresentativeNameToInvoiceRecipients < ActiveRecord::Migration[8.0]
  def change
    add_column :invoice_recipients, :representative_name, :string
  end
end
