class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name
      t.integer :base_price
      t.boolean :is_active

      t.timestamps
    end
  end
end
