class Cart < ApplicationRecord
  belongs_to :user
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items
  
  def total_amount(user_level = nil)
    cart_items.sum { |item| item.subtotal(user_level, user) }
  end
  
  def total_amount_for_user(user)
    cart_items.sum do |item|
      unit_price = item.unit_price_for_user(user)
      # 骨髄幹細胞培養上清液（ID: 1）の場合は、2cc単位の価格 × 保存数量
      # 内部では既に5倍で保存されているので、そのまま計算
      unit_price * item.quantity
    end
  end
  
  def total_items
    cart_items.sum do |item|
      # 骨髄幹細胞培養上清液（ID: 1）の場合は、保存されている数量を5で割って表示
      (item.product_id == 1) ? (item.quantity / 5) : item.quantity
    end
  end
  
  def has_stem_cell_products?
    cart_items.joins(:product).where(products: { category: [nil, 'sl'] }).exists?
  end
  
  def has_wott_products?
    cart_items.joins(:product).where(products: { category: 'wott' }).exists?
  end
  
  def has_ms_products?
    cart_items.joins(:product).where(products: { category: 'ms' }).exists?
  end
  
  def clear_all_items
    cart_items.destroy_all
  end
  
  def get_current_category
    return nil if cart_items.empty?
    
    first_product = cart_items.first.product
    category = first_product.category
    
    # 幹細胞商品（categoryがnilまたは'sl'）は'stem_cell'として扱う
    return 'stem_cell' if category.nil? || category == 'sl'
    
    category
  end
end
