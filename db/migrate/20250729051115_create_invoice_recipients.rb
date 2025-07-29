class CreateInvoiceRecipients < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_recipients do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :email
      t.string :postal_code
      t.string :address
      t.string :tel
      t.string :department
      t.text :notes

      t.timestamps
    end
  end
end
