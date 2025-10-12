class OrdersController < ApplicationController
  before_action :authenticate_user!
  
  def index
    # 予約・注文メニューページ
  end

  def products
    # 幹細胞培養上精液の商品一覧（価格情報があるもののみ）
    @products = Product.joins(:product_prices)
                      .where(product_prices: { level_id: current_user.level_id })
                      .distinct
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
      # 購入レコードを作成
      purchase = Purchase.create!(
        user: current_user,        # 購入者
        purchased_at: Time.current,
        payment_type: params[:payment_type] || 'cash',  # デフォルトは銀行振込
        status: 'built'  # 初期ステータス
      )
      
      # 購入アイテムを作成
      @cart.cart_items.each do |cart_item|
        user_price = cart_item.product.price_for(current_user.level_symbol) || 0
        
        PurchaseItem.create!(
          purchase: purchase,
          product: cart_item.product,
          quantity: cart_item.quantity,
          unit_price: cart_item.product.base_price,  # 基本価格
          seller_price: user_price  # ユーザーの購入価格
        )
      end
      
      # 購入請求書を自動生成
      purchase_invoice = purchase.create_purchase_invoice!(
        invoice_number: PurchaseInvoice.generate_invoice_number,
        invoice_date: Date.current,
        due_date: Date.current + 30.days,
        total_amount: purchase.total_price,
        status: PurchaseInvoice::DRAFT,
        notes: "商品購入に関する請求書"
      )
      
      # カートをクリア
      @cart.cart_items.destroy_all
      
      Rails.logger.info "Purchase #{purchase.id} and PurchaseInvoice #{purchase_invoice.id} created successfully"
    end
    
    redirect_to purchase_invoices_path, notice: '注文が完了しました。請求書を確認してください。'
  rescue => e
    Rails.logger.error "Purchase process error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to orders_checkout_path, alert: '購入処理中にエラーが発生しました'
  end
end
