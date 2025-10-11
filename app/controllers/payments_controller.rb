class PaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_cart_has_items

  def select_method
    @cart = current_user.cart
    @total_amount = @cart.total_amount(current_user.level_symbol)
  end

  def bank_transfer
    @cart = current_user.cart
    
    # 購入処理を実行
    result = process_purchase('cash')
    
    if result[:success]
      # 銀行振込案内メールを送信（請求書PDF添付）
      begin
        OrderMailer.bank_transfer_instructions(result[:purchase], result[:purchase_invoice]).deliver_now
        redirect_to purchase_invoices_path, notice: '注文が完了しました。銀行振込の詳細と請求書をメールでお送りしました。'
      rescue => e
        Rails.logger.error "Failed to send bank transfer email: #{e.message}"
        redirect_to purchase_invoices_path, notice: '注文が完了しました。銀行振込の詳細は別途ご連絡いたします。'
      end
    else
      redirect_to select_method_payments_path, alert: result[:error]
    end
  end

  def credit_card
    @cart = current_user.cart
    
    # 購入処理を実行
    result = process_purchase('credit')
    
    if result[:success]
      redirect_to orders_path, notice: '注文が完了しました。クレジットカード決済を処理中です。'
    else
      redirect_to select_method_payments_path, alert: result[:error]
    end
  end

  private

  def ensure_cart_has_items
    @cart = current_user.cart
    if @cart.nil? || @cart.cart_items.empty?
      redirect_to orders_products_path, alert: 'カートに商品がありません。'
    end
  end

  def process_purchase(payment_type)
    begin
      ActiveRecord::Base.transaction do
        # Purchaseレコードを作成
        purchase = Purchase.create!(
          user: current_user,
          buyer: current_user,
          purchased_at: Time.current,
          payment_type: payment_type
        )

        # PurchaseItemsを作成
        @cart.cart_items.each do |cart_item|
          user_price = cart_item.product.price_for(current_user.level_symbol) || 0
          purchase.purchase_items.create!(
            product: cart_item.product,
            quantity: cart_item.quantity,
            unit_price: user_price,
            seller_price: user_price  # 販売店の購入価格（同じ価格を設定）
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

        { success: true, purchase: purchase, purchase_invoice: purchase_invoice }
      end
    rescue => e
      Rails.logger.error "Purchase failed: #{e.message}"
      { success: false, error: '注文処理中にエラーが発生しました。' }
    end
  end
end