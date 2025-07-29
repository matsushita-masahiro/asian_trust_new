class CreateInvoiceBases < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_bases do |t|
      t.references :user, null: false, foreign_key: true
      t.string :company_name
      t.string :postal_code
      t.text :address
      t.string :department
      t.string :email
      t.text :notes

      t.timestamps
    end
  end
end
