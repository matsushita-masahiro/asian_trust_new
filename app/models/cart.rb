class Cart < ApplicationRecord
  belongs_to :user
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items
  
  def total_amount(user_level = nil)
    cart_items.sum { |item| item.subtotal(user_level, user) }
  end
  
  def total_amount_for_user(user)
    cart_items.sum { |item| item.unit_price_for_user(user) * item.quantity }
  end
  
  def total_items
    cart_items.sum(:quantity)
  end
end
