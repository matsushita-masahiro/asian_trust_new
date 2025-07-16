class CreateProductPrices < ActiveRecord::Migration[8.0]
  def change
    create_table :product_prices do |t|
      t.references :product, null: false, foreign_key: true
      t.references :level, null: false, foreign_key: true
      t.integer :price

      t.timestamps
    end
  end
end
