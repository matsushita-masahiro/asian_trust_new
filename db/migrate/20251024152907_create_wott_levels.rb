class CreateWottLevels < ActiveRecord::Migration[8.0]
  def change
    create_table :wott_levels do |t|
      t.string :name, null: false
      t.integer :value, null: false

      t.timestamps
    end
    
    add_index :wott_levels, :name, unique: true
    add_index :wott_levels, :value, unique: true
  end
end
