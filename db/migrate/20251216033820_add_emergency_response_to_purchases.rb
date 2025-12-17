class AddEmergencyResponseToPurchases < ActiveRecord::Migration[8.0]
  def change
    add_column :purchases, :emergency_reservation_response, :text
    add_column :purchases, :emergency_reservation_responded_at, :datetime
    add_column :purchases, :emergency_reservation_responded_by, :integer
  end
end
