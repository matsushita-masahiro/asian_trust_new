class CartsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_cart
  
  def show
    @cart_items = @cart.cart_items.includes(:product)
  end

  def add_item
    product = Product.find(params[:product_id])
    quantity = params[:quantity].to_i
    
    if quantity <= 0
      redirect_back(fallback_location: orders_products_path, alert: '数量を選択してください')
      return
    end
    
    cart_item = @cart.cart_items.find_by(product: product)
    
    if cart_item
      cart_item.update!(quantity: cart_item.quantity + quantity)
    else
      @cart.cart_items.create!(product: product, quantity: quantity)
    end
    
    redirect_back(fallback_location: orders_products_path, notice: 'カートに追加しました')
  end

  def remove_item
    cart_item = @cart.cart_items.find(params[:cart_item_id])
    cart_item.destroy!
    
    redirect_to cart_path, notice: '商品をカートから削除しました'
  end

  def update_item
    cart_item = @cart.cart_items.find(params[:cart_item_id])
    quantity = params[:quantity].to_i
    
    if quantity <= 0
      cart_item.destroy!
      message = '商品をカートから削除しました'
    else
      cart_item.update!(quantity: quantity)
      message = '数量を更新しました'
    end
    
    redirect_to cart_path, notice: message
  end
  
  private
  
  def ensure_cart
    @cart = current_user.ensure_cart
  end
end
