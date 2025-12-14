class AddInvoiceRegistrationNumberToInvoiceRecipients < ActiveRecord::Migration[8.0]
  def change
    add_column :invoice_recipients, :invoice_registration_number, :string
  end
end
