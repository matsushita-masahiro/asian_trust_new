class CreateClinicBusinessHours < ActiveRecord::Migration[8.0]
  def change
    create_table :clinic_business_hours do |t|
      t.references :clinic, null: false, foreign_key: true
      t.integer :weekday, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false

      t.timestamps
    end
    
    add_index :clinic_business_hours, [:clinic_id, :weekday], unique: true
  end
end
