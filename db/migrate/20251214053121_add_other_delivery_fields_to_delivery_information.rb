class AddOtherDeliveryFieldsToDeliveryInformation < ActiveRecord::Migration[8.0]
  def change
    add_column :delivery_informations, :recipient_name, :string
    add_column :delivery_informations, :postal_code, :string
    add_column :delivery_informations, :phone_number, :string
  end
end
