class AddUnitInfoToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :unit_quantity, :decimal
    add_column :products, :unit_label, :string
  end
end
