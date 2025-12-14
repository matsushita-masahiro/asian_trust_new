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
      
      # 骨髄幹細胞培養上清液（ID: 1）の場合は、10cc単位なので数量を5倍にする
      actual_quantity = (product.id == 1) ? (quantity * 5) : quantity
      
      # 既存のカートアイテムがあれば数量を追加、なければ新規作成
      cart_item = @cart.cart_items.find_by(product: product)
      if cart_item
        cart_item.update!(quantity: cart_item.quantity + actual_quantity)
      else
        @cart.cart_items.create!(product: product, quantity: actual_quantity)
      end
    else
      @cart = current_user.cart
    end
    
    if @cart.nil? || @cart.cart_items.empty?
      redirect_to orders_path, alert: 'カートが空です'
      return
    end
    
    # カートアイテムから配送先情報を取得
    @cart_items_with_delivery = @cart.cart_items.map do |item|
      delivery_info = {
        item: item,
        delivery_type: item.delivery_type || (item.product.id == 1 ? 'clinic' : 'home'),
        clinic_id: item.clinic_id,
        address_type: item.address_type || 'registration'
      }
      
      Rails.logger.info "=== CART ITEM DELIVERY DEBUG ==="
      Rails.logger.info "Item ID: #{item.id}, Product: #{item.product.name}"
      Rails.logger.info "Delivery Type: #{delivery_info[:delivery_type]}"
      Rails.logger.info "Clinic ID: #{delivery_info[:clinic_id]}"
      Rails.logger.info "Address Type: #{delivery_info[:address_type]}"
      Rails.logger.info "Other Info: recipient=#{item.other_recipient_name}, postal=#{item.other_postal_code}, address=#{item.other_address}"
      Rails.logger.info "================================="
      
      delivery_info
    end
    
    # 配送先の検証
    clinic_items = @cart_items_with_delivery.select { |i| i[:delivery_type] == 'clinic' }
    home_items = @cart_items_with_delivery.select { |i| i[:delivery_type] == 'home' }
    other_items = @cart_items_with_delivery.select { |i| i[:delivery_type] == 'other' }
    
    # クリニック配送の商品でクリニックが未選択の場合
    if clinic_items.any? { |i| i[:clinic_id].blank? }
      redirect_to cart_path, alert: 'クリニック配送の商品はクリニックを選択してください'
      return
    end
    
    # 住所配送の商品で住所が未登録の場合
    if home_items.any?
      address_type = home_items.first[:address_type]
      @selected_address = address_type == 'shipping' ? current_user.shipping_address : current_user.registration_address
      
      if @selected_address.blank?
        redirect_to cart_path, alert: 'マイアカウントで配送先住所を登録してください'
        return
      end
    end
    
    # その他配送の商品で必要情報が未入力の場合
    if other_items.any?
      incomplete_other_items = other_items.select do |i|
        item = i[:item]
        item.other_recipient_name.blank? || item.other_postal_code.blank? || 
        item.other_address.blank? || item.other_phone_number.blank?
      end
      
      if incomplete_other_items.any?
        redirect_to cart_path, alert: 'その他配送を選択した商品は、すべての配送先情報を入力してください'
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
        status: PurchaseInvoice::SENT,
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
    # 配送先ごとにグループ化して重複を避ける
    delivery_destinations = {}
    
    @cart.cart_items.each do |cart_item|
      delivery_type = cart_item.delivery_type || (cart_item.product.id == 1 ? 'clinic' : 'home')
      
      # 配送先のキーを生成（同じ配送先をまとめるため）
      destination_key = case delivery_type
      when 'clinic'
        "clinic_#{cart_item.clinic_id}"
      when 'home'
        "home_#{cart_item.address_type || 'registration'}"
      when 'other'
        "other_#{cart_item.other_postal_code}_#{cart_item.other_address}"
      else
        "unknown_#{cart_item.id}"
      end
      
      # 既に同じ配送先がある場合はスキップ
      next if delivery_destinations.key?(destination_key)
      
      Rails.logger.info "=== CREATE DELIVERY INFORMATION DEBUG ==="
      Rails.logger.info "Purchase ID: #{purchase.id}"
      Rails.logger.info "Destination Key: #{destination_key}"
      Rails.logger.info "Delivery type: #{delivery_type}"
      Rails.logger.info "============================================"
      
      # 配送先住所を取得してスナップショットとして保存
      delivery_address = get_delivery_address_for_item(cart_item)
      
      # その他配送の場合の追加情報
      recipient_name = nil
      postal_code = nil
      phone_number = nil
      
      if delivery_type == 'other'
        recipient_name = cart_item.other_recipient_name
        postal_code = cart_item.other_postal_code
        phone_number = cart_item.other_phone_number
        
        Rails.logger.info "Other delivery info: recipient_name=#{recipient_name}, postal_code=#{postal_code}, phone_number=#{phone_number}"
      end
      
      Rails.logger.info "Creating DeliveryInformation with: delivery_type=#{delivery_type}, delivery_address=#{delivery_address}, recipient_name=#{recipient_name}, postal_code=#{postal_code}, phone_number=#{phone_number}"
      
      delivery_info = DeliveryInformation.create!(
        purchase: purchase,
        delivery_type: delivery_type,
        clinic_id: cart_item.clinic_id,
        address_type: cart_item.address_type,
        delivery_address: delivery_address,
        recipient_name: recipient_name,
        postal_code: postal_code,
        phone_number: phone_number,
        delivery_notes: params[:delivery_notes]
      )
      
      # 作成した配送先を記録
      delivery_destinations[destination_key] = delivery_info
      
      Rails.logger.info "Created delivery_information: ID #{delivery_info.id}, Type: #{delivery_info.delivery_type}"
    end
  rescue => e
    Rails.logger.error "Failed to create delivery_information: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  def get_delivery_address_for_item(cart_item)
    delivery_type = cart_item.delivery_type || (cart_item.product.id == 1 ? 'clinic' : 'home')
    
    case delivery_type
    when 'home'
      # 自宅配送の住所
      if cart_item.address_type == 'shipping' && current_user.shipping_address
        "#{current_user.shipping_address.postal_code}|#{current_user.shipping_address.address}"
      elsif current_user.registration_address
        "#{current_user.registration_address.postal_code}|#{current_user.registration_address.address}"
      else
        ""
      end
    when 'clinic'
      # クリニック配送の住所
      if cart_item.clinic_id.present?
        clinic = User.joins(:invoice_base).find_by(id: cart_item.clinic_id)
        if clinic&.invoice_base
          "#{clinic.invoice_base.postal_code}|#{clinic.invoice_base.address}|#{clinic.name}"
        else
          ""
        end
      else
        ""
      end
    when 'other'
      # その他配送の住所
      if cart_item.other_postal_code.present? && cart_item.other_address.present?
        "#{cart_item.other_postal_code}|#{cart_item.other_address}"
      else
        Rails.logger.error "Other delivery info missing: postal_code=#{cart_item.other_postal_code}, address=#{cart_item.other_address}"
        ""
      end
    else
      ""
    end
  end
end
