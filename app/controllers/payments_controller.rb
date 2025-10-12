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
        Rails.logger.info "Starting bank transfer email process for Purchase #{result[:purchase].id}"
        
        # PDF表示用の情報を取得
        @purchase = result[:purchase]
        @purchase_invoice = result[:purchase_invoice]
        @user = current_user
        
        # PDF生成とS3アップロード
        pdf_service = PurchaseInvoicePdfService.new(@purchase_invoice)
        Rails.logger.info "Generating PDF for PurchaseInvoice #{@purchase_invoice.id}"
        pdf_content = pdf_service.generate_and_upload_pdf
        Rails.logger.info "PDF generated and uploaded successfully for PurchaseInvoice #{@purchase_invoice.id}"
        
        # DBから会社情報を取得（invoice_basesテーブルから）
        # 管理者ユーザーのinvoice_baseを取得（admin=trueのユーザー）
        admin_user = User.find_by(admin: true)
        invoice_base = admin_user&.invoice_base
        
        if invoice_base
          @company_info = {
            name: invoice_base.company_name || "株式会社アジアビジネストラスト",
            department: invoice_base.department || "アジアビジネストラスト事業部",
            address: invoice_base.address || "〒104-0061 東京都中央区銀座4丁目6-1",
            building: "", # invoice_baseにはbuilding項目がないため空文字
            tel: "TEL:03-5904-8148", # 固定値（DBに項目がない）
            email: invoice_base.email || "abt1@asia-b-t.com",
            footer: "アジアビジネストラスト 事務局", # 固定値
            registration_number: "T4210001009156" # 固定値
          }
          
          @bank_info = {
            name: invoice_base.bank_name || "楽天銀行",
            branch: invoice_base.bank_branch_name || "第二営業支店",
            branch_code: "252", # 固定値（DBに項目がない）
            account_type: invoice_base.bank_account_type || "普通預金",
            account_number: invoice_base.bank_account_number || "7747552",
            account_name: invoice_base.bank_account_name || @company_info[:name]
          }
        else
          # DBに情報がない場合はデフォルト値を使用
          Rails.logger.warn "No invoice_base found for admin user, using default values"
          @company_info = {
            name: "株式会社アジアビジネストラスト",
            department: "アジアビジネストラスト事業部",
            address: "〒104-0061 東京都中央区銀座4丁目6-1",
            building: "銀座医科ビル3階",
            tel: "TEL:03-5904-8148",
            email: "abt1@asia-b-t.com",
            footer: "アジアビジネストラスト 事務局",
            registration_number: "T4210001009156"
          }
          
          @bank_info = {
            name: "楽天銀行",
            branch: "第二営業支店",
            branch_code: "252",
            account_type: "普通預金",
            account_number: "7747552",
            account_name: @company_info[:name]
          }
        end
        
        # 送付先メールアドレスを取得（invoice_recipientsテーブルから）
        # ユーザーの最初のinvoice_recipientのemailを使用
        invoice_recipient = current_user.invoice_recipients.first
        @recipient_email = invoice_recipient&.email || current_user.email
        
        Rails.logger.info "Recipient email: #{@recipient_email}"
        Rails.logger.info "Using invoice_recipient: #{invoice_recipient.present?}"
        
        # メール送信（PDFを添付）
        Rails.logger.info "Sending bank transfer email for Purchase #{@purchase.id}"
        OrderMailer.bank_transfer_instructions(
          @purchase, 
          @purchase_invoice,
          {
            company_info: @company_info,
            bank_info: @bank_info,
            recipient_email: @recipient_email
          },
          pdf_content
        ).deliver_now
        
        Rails.logger.info "Bank transfer email sent successfully for Purchase #{@purchase.id}"
        redirect_to purchase_invoices_path, notice: '注文が完了しました。銀行振込の詳細と請求書をメールでお送りしました。'
      rescue => e
        Rails.logger.error "Failed to send bank transfer email: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
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
        purchase_invoice = PurchaseInvoice.create!(
          purchase: purchase,
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