class CreateClinicReservations < ActiveRecord::Migration[8.0]
  def change
    create_table :clinic_reservations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :purchase, null: false, foreign_key: true
      t.integer :clinic_id
      t.text :treatment_methods
      t.date :preferred_date_1
      t.string :preferred_time_1
      t.date :preferred_date_2
      t.string :preferred_time_2
      t.date :preferred_date_3
      t.string :preferred_time_3
      t.text :disease_name
      t.text :current_treatment
      t.text :current_condition
      t.text :questions
      t.integer :status

      t.timestamps
    end
  end
end
