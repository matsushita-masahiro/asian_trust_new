class Cart < ApplicationRecord
  belongs_to :user
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items
  
  def total_amount(user_level = nil)
    cart_items.sum { |item| item.subtotal(user_level) }
  end
  
  def total_items
    cart_items.sum(:quantity)
  end
end
