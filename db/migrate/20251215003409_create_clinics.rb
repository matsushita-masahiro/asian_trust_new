class CreateClinics < ActiveRecord::Migration[8.0]
  def change
    create_table :clinics do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :name, null: false
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end
  end
end
