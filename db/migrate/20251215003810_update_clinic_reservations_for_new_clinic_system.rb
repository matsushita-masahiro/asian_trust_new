class UpdateClinicReservationsForNewClinicSystem < ActiveRecord::Migration[8.0]
  def up
    # Since there are no existing clinic_reservations with clinic_id set,
    # we just need to add the foreign key constraint to the new clinics table
    
    # Add foreign key constraint to new clinics table
    add_foreign_key :clinic_reservations, :clinics, column: :clinic_id
  end
  
  def down
    # Remove foreign key to clinics
    remove_foreign_key :clinic_reservations, :clinics, column: :clinic_id
  end
end
