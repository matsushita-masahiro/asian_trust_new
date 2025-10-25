class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product
  
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  
  def subtotal(user_level = nil, user = nil)
    if product.category == 'wott'
      # WOTT商品は全員一律でbase_price
      price = product.base_price || 0
    else
      price = product.price_for(user_level) || 0
    end
    quantity * price
  end
  
  def unit_price_for_user(user)
    if product.category == 'wott'
      # WOTT商品は全員一律でbase_price
      product.base_price || 0
    else
      product.price_for(user.level_symbol) || 0
    end
  end
end
