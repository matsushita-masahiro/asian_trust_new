class ChangeTaxIncludedDefaultToFalse < ActiveRecord::Migration[8.0]
  def change
    change_column_default :products, :tax_included, from: true, to: false
  end
end
