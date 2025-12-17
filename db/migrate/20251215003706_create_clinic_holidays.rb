class CreateClinicHolidays < ActiveRecord::Migration[8.0]
  def change
    create_table :clinic_holidays do |t|
      t.references :clinic, null: false, foreign_key: true
      t.date :date
      t.integer :weekday
      t.string :reason, null: false

      t.timestamps
    end
  end
end
