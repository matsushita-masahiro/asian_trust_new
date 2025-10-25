class ChangeProductPricesLevelIdToOptional < ActiveRecord::Migration[8.0]
  def change
    change_column_null :product_prices, :level_id, true
  end
end
