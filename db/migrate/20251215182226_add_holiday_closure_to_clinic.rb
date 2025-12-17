class AddHolidayClosureToClinic < ActiveRecord::Migration[8.0]
  def change
    add_column :clinics, :holiday_closure_enabled, :boolean, default: true
  end
end
