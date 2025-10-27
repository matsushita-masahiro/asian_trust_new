class CreateShippingFees < ActiveRecord::Migration[8.0]
  def change
    create_table :shipping_fees do |t|
      t.references :purchase, null: false, foreign_key: true
      t.string :shipping_type
      t.integer :amount

      t.timestamps
    end
  end
end
