class AddDeliveryInfoToCartItems < ActiveRecord::Migration[8.0]
  def change
    add_column :cart_items, :delivery_type, :string
    add_column :cart_items, :clinic_id, :integer
    add_column :cart_items, :address_type, :string
  end
end
