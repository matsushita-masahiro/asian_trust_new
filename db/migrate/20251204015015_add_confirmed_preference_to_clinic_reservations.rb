class AddConfirmedPreferenceToClinicReservations < ActiveRecord::Migration[8.0]
  def change
    add_column :clinic_reservations, :confirmed_preference, :integer
    add_column :clinic_reservations, :confirmed_date, :date
    add_column :clinic_reservations, :confirmed_time, :string
  end
end
