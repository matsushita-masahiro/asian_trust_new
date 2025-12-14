class AddOtherDeliveryFieldsToCartItems < ActiveRecord::Migration[8.0]
  def change
    add_column :cart_items, :other_recipient_name, :string
    add_column :cart_items, :other_postal_code, :string
    add_column :cart_items, :other_address, :text
    add_column :cart_items, :other_phone_number, :string
  end
end
