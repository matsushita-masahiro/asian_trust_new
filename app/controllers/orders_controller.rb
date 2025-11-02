class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :check_purchase_permission, only: [:products, :checkout, :purchase]
  
  def index
    # 予約・注文メニューページ
  end

  def products
    @category = params[:category] || 'sl' # デフォルトは上清液
    @cart = current_user.ensure_cart
    
    case @category
    when 'wott'
      # WOTT商品の場合
      if current_user.wott_level.present?
        @products = Product.active.where(category: 'wott')
        Rails.logger.info "DEBUG: WOTT products count: #{@products.count}"
        Rails.logger.info "DEBUG: User WOTT level: #{current_user.wott_level_name}"
        @products.each do |product|
          price = product.wott_price_for(current_user.wott_level_symbol)
          Rails.logger.info "DEBUG: Product #{product.name} price for #{current_user.wott_level_name}: #{price}"
        end
      else
        @products = Product.none
        flash.now[:alert] = 'WOTT商品を購入するにはWOTTレベルが必要です。'
      end
    when 'ms', 'mannerssound'
      # MANNERSSOUND商品の場合
      Rails.logger.info "DEBUG: MANNERSSOUND category selected"
      Rails.logger.info "DEBUG: User level ID: #{current_user.level_id}"
      
      all_ms_products = Product.where(category: 'ms')
      Rails.logger.info "DEBUG: All MS products count: #{all_ms_products.count}"
      
      @products = Product.joins(:product_prices)
                        .where(category: 'ms', product_prices: { level_id: current_user.level_id })
                        .distinct
      Rails.logger.info "DEBUG: Filtered MS products count: #{@products.count}"
    else
      # 上清液商品の場合は従来のレベルで価格チェック
      @products = Product.joins(:product_prices)
                        .where(category: 'sl', product_prices: { level_id: current_user.level_id })
                        .distinct
    end
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
    
    if @cart.nil? || @cart.cart_items.empty?
      redirect_to orders_path, alert: 'カートが空です'
      return
    end
    
    # 配送情報を設定
    @delivery_type = params[:delivery_type] || 'home'
    @address_type = params[:address_type] || 'registration'
    @clinic_id = params[:clinic_id]
    
    # 選択された住所を取得
    case @address_type
    when 'shipping'
      @selected_address = current_user.shipping_address
    else
      @selected_address = current_user.registration_address
    end
    
    # 住所が選択されていない場合はカートに戻す
    if @delivery_type.in?(['home', 'multiple']) && @selected_address.blank?
      redirect_to cart_path, alert: '配送先住所を選択してください'
      return
    end
    
    # クリニック配送の場合はクリニック情報を取得
    if @delivery_type.in?(['clinic', 'multiple']) && @clinic_id.present?
      @selected_clinic = User.joins(:invoice_base).find_by(id: @clinic_id)
      if @selected_clinic.blank?
        redirect_to cart_path, alert: '配送先クリニックを選択してください'
        return
      end
    end
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
        # 商品カテゴリーに応じて適切な価格を取得
        user_price = cart_item.product.price_for_user(current_user) || 0
        
        PurchaseItem.create!(
          purchase: purchase,
          product: cart_item.product,
          quantity: cart_item.quantity,
          unit_price: cart_item.product.base_price,  # 基本価格
          seller_price: user_price  # ユーザーの購入価格
        )
      end
      
      # 配送情報を作成
      create_delivery_information(purchase)
      
      # 送料データを作成
      purchase.create_shipping_fees!
      
      # 購入請求書を自動生成
      purchase_invoice = purchase.create_purchase_invoice!(
        invoice_number: PurchaseInvoice.generate_invoice_number,
        invoice_date: Date.current,
        due_date: purchase.purchased_at.to_date + 1.week,
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

  private

  def check_purchase_permission
    # アドバイザー認定前レベル（value: 4）は商品購入不可
    if current_user.level&.name == 'アドバイザー認定前'
      redirect_to root_path, alert: 'アドバイザー認定前レベルでは商品を購入できません。正式なアドバイザーレベルへの昇格をお待ちください。'
    end
  end

  def create_delivery_information(purchase)
    delivery_type = params[:delivery_type] || 'home'
    address_type = params[:address_type] || 'registration'
    clinic_id = params[:clinic_id]
    
    Rails.logger.info "=== CREATE DELIVERY INFORMATION DEBUG ==="
    Rails.logger.info "Purchase ID: #{purchase.id}"
    Rails.logger.info "Delivery type: #{delivery_type}"
    Rails.logger.info "Address type: #{address_type}"
    Rails.logger.info "Clinic ID: #{clinic_id}"
    Rails.logger.info "============================================"
    
    # 配送先住所を取得してスナップショットとして保存
    delivery_address = get_delivery_address(address_type, clinic_id)
    
    delivery_info = DeliveryInformation.create!(
      purchase: purchase,
      delivery_type: delivery_type,
      clinic_id: clinic_id,
      address_type: address_type,
      delivery_address: delivery_address,
      delivery_notes: params[:delivery_notes]
    )
    
    Rails.logger.info "Created delivery_information: ID #{delivery_info.id}, Type: #{delivery_info.delivery_type}"
  rescue => e
    Rails.logger.error "Failed to create delivery_information: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  def get_delivery_address(address_type, clinic_id)
    addresses = []
    
    # 自宅配送の住所
    if address_type == 'shipping' && current_user.shipping_address
      addresses << "#{current_user.shipping_address.postal_code}|#{current_user.shipping_address.address}"
    elsif current_user.registration_address
      addresses << "#{current_user.registration_address.postal_code}|#{current_user.registration_address.address}"
    end
    
    # クリニック配送の住所
    if clinic_id.present?
      clinic = User.joins(:invoice_base).find_by(id: clinic_id)
      if clinic&.invoice_base
        addresses << "#{clinic.invoice_base.postal_code}|#{clinic.invoice_base.address}|#{clinic.name}"
      end
    end
    
    addresses.join("\n")
  end
end
