class AddWottLevelToProductPrices < ActiveRecord::Migration[8.0]
  def change
    add_reference :product_prices, :wott_level, null: true, foreign_key: true
  end
end
