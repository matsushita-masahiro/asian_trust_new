class AddTaxIncludedAndDescriptionToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :tax_included, :boolean, default: true, null: false
  end
end
