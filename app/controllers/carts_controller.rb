class CartsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_purchase_permission
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
    
    # 追加しようとする商品のカテゴリを判定
    product_category = product.category
    new_category = if product_category.nil? || product_category == 'sl'
                     'stem_cell'
                   else
                     product_category
                   end
    
    # カートに既に商品がある場合、カテゴリチェック
    current_category = @cart.get_current_category
    if current_category && current_category != new_category
      category_names = {
        'stem_cell' => '幹細胞商品',
        'wott' => 'WOTT商品',
        'ms' => 'マナーズサウンド商品'
      }
      
      current_name = category_names[current_category] || current_category
      new_name = category_names[new_category] || new_category
      
      redirect_back(
        fallback_location: orders_products_path, 
        alert: "カートに#{current_name}が入っています。#{new_name}と一緒に購入することはできません。先にカートを空にしてから追加してください。"
      )
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
  
  def check_purchase_permission
    # アドバイザー認定前レベル（value: 4）は商品購入不可
    if current_user.level&.name == 'アドバイザー認定前'
      redirect_to root_path, alert: 'アドバイザー認定前レベルでは商品を購入できません。正式なアドバイザーレベルへの昇格をお待ちください。'
    end
  end
  
  def ensure_cart
    @cart = current_user.ensure_cart
  end
end
