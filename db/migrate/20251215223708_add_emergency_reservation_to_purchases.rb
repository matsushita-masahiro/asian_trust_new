class AddEmergencyReservationToPurchases < ActiveRecord::Migration[8.0]
  def change
    add_column :purchases, :emergency_reservation_requested, :boolean, default: false
    add_column :purchases, :emergency_reservation_message, :text
  end
end
