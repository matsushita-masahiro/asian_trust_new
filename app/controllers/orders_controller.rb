class OrdersController < ApplicationController
  before_action :authenticate_user!
  
  def index
    # 予約・注文メニューページ
  end

  def products
    # 幹細胞培養上精液の商品一覧
    @products = Product.all
    @cart = current_user.ensure_cart
  end

  def checkout
    # 今すぐ購入の場合は一時的にカートに追加
    if params[:product_id] && params[:quantity]
      @cart = current_user.ensure_cart
      product = Product.find(params[:product_id])
      quantity = params[:quantity].to_i
      
      # 既存のカートアイテムがあれば数量を追加、なければ新規作成
      cart_item = @cart.cart_items.find_by(product: product)
      if cart_item
        cart_item.update!(quantity: cart_item.quantity + quantity)
      else
        @cart.cart_items.create!(product: product, quantity: quantity)
      end
    else
      @cart = current_user.cart
    end
    
    redirect_to orders_path, alert: 'カートが空です' if @cart.nil? || @cart.cart_items.empty?
  end
  
  def purchase
    @cart = current_user.cart
    
    if @cart.nil? || @cart.cart_items.empty?
      redirect_to orders_products_path, alert: 'カートが空です'
      return
    end
    
    # 購入処理を実行
    ActiveRecord::Base.transaction do
      purchase = Purchase.create!(
        user: current_user,
        purchased_at: Time.current,
        total_amount: @cart.total_amount(current_user.level_symbol)
      )
      
      @cart.cart_items.each do |cart_item|
        PurchaseItem.create!(
          purchase: purchase,
          product: cart_item.product,
          quantity: cart_item.quantity,
          unit_price: cart_item.product.price_for(current_user.level_symbol) || 0
        )
      end
      
      # カートをクリア
      @cart.cart_items.destroy_all
    end
    
    redirect_to orders_path, notice: '購入が完了しました'
  rescue => e
    redirect_to orders_checkout_path, alert: '購入処理中にエラーが発生しました'
  end
end
