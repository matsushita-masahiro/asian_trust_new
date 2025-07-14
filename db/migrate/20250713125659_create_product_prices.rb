class CreateProductPrices < ActiveRecord::Migration[8.0]
  def change
    create_table :product_prices do |t|
      t.references :product, null: false, foreign_key: true
      t.integer :agent_level
      t.integer :price

      t.timestamps
    end
  end
end
