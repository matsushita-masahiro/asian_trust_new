class AddIncentiveRateToProductPrices < ActiveRecord::Migration[8.0]
  def change
    add_column :product_prices, :incentive_rate, :decimal, precision: 5, scale: 2
  end
end
