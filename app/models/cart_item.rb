class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product
  
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  
  def subtotal(user_level = nil)
    price = product.price_for(user_level) || 0
    quantity * price
  end
end
