class CreateLevels < ActiveRecord::Migration[7.0]
  def change
    create_table :levels do |t|
      t.string :name, null: false
      t.integer :value, null: false, unique: true
      t.timestamps
    end
    add_index :levels, :value, unique: true
  end
end