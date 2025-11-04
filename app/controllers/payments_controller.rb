class PaymentsController < ApplicationController
  
  before_action :authenticate_user!
  before_action :ensure_cart_has_items

  def select_method
    @cart = current_user.cart
    @total_amount = @cart.total_amount_for_user(current_user)
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
        
        # DBから会社情報を取得（invoice_recipientテーブルから）
        # 管理者ユーザーのinvoice_recipientを取得（admin=trueのユーザー）
        admin_user = User.find_by(admin: true)
        invoice_recipient = admin_user&.invoice_recipient
        invoice_base = admin_user&.invoice_base
        
        if invoice_recipient
          @company_info = {
            name: invoice_recipient.company_name || ENV['COMPANY_NAME'] || "株式会社アジアビジネストラスト",
            department: invoice_recipient.department || ENV['COMPANY_DEPARTMENT'] || "アジアビジネストラスト事業部",
            address: invoice_recipient.address || "〒#{ENV['COMPANY_POSTAL_CODE'] || '104-0061'} #{ENV['COMPANY_ADDRESS'] || '東京都中央区銀座4丁目6-1'}",
            building: ENV['COMPANY_BUILDING'] || "", # invoice_recipientにはbuilding項目がないため環境変数から取得
            tel: invoice_recipient.tel || ENV['COMPANY_TEL'] || "03-5904-8148",
            email: invoice_recipient.email || ENV['COMPANY_EMAIL'] || "abt1@asia-b-t.com",
            footer: ENV['COMPANY_FOOTER'] || "アジアビジネストラスト 事務局",
            registration_number: ENV['COMPANY_REGISTRATION_NUMBER'] || "T4210001009156"
          }
          
          @bank_info = {
            name: invoice_base.bank_name || ENV['BANK_NAME'] || "楽天銀行",
            branch: invoice_base.bank_branch_name || ENV['BANK_BRANCH'] || "第三営業支店",
            branch_code: ENV['BANK_BRANCH_CODE'] || "252", # 固定値（DBに項目がない）
            account_type: invoice_base.bank_account_type || ENV['BANK_ACCOUNT_TYPE'] || "普通預金",
            account_number: invoice_base.bank_account_number || ENV['BANK_ACCOUNT_NUMBER'] || "7247552",
            account_name: invoice_base.bank_account_name || @company_info[:name]
          }
        else
          # DBに情報がない場合はデフォルト値を使用
          Rails.logger.warn "No invoice_recipient found for admin user, using default values"
          @company_info = {
            name: ENV['COMPANY_NAME'] || "株式会社アジアビジネストラスト",
            department: ENV['COMPANY_DEPARTMENT'] || "アジアビジネストラスト事業部",
            address: "#{ENV['COMPANY_POSTAL_CODE'] || '104-0061'} #{ENV['COMPANY_ADDRESS'] || '東京都中央区銀座4丁目6-1 銀座医科ビル3階'}",
            tel: "#{ENV['COMPANY_TEL'] || '03-5904-8148'}",
            email: ENV['COMPANY_EMAIL'] || "abt1@asia-b-t.com",
            footer: ENV['COMPANY_FOOTER'] || "アジアビジネストラスト 事務局",
            registration_number: ENV['COMPANY_REGISTRATION_NUMBER'] || "T4210001009156"
          }
          
          @bank_info = {
            name: ENV['BANK_NAME'] || "楽天銀行",
            branch: ENV['BANK_BRANCH'] || "第三営業支店",
            branch_code: ENV['BANK_BRANCH_CODE'] || "252",
            account_type: ENV['BANK_ACCOUNT_TYPE'] || "普通預金",
            account_number: ENV['BANK_ACCOUNT_NUMBER'] || "7247552",
            account_name: @company_info[:name]
          }
        end
        
        # 送付先メールアドレスを取得（invoice_recipientテーブルから）
        # ユーザーのinvoice_recipientのemailを使用
        invoice_recipient = current_user.invoice_recipient
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
        redirect_to my_history_purchases_path, notice: '注文が完了しました。銀行振込の詳細と請求書をメールでお送りしました。'
      rescue => e
        Rails.logger.error "Failed to send bank transfer email: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        redirect_to my_history_purchases_path, notice: '注文が完了しました。銀行振込の詳細は別途ご連絡いたします。'
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
          purchased_at: Time.current,
          payment_type: payment_type
        )

        # PurchaseItemsを作成
        @cart.cart_items.each do |cart_item|
          # 商品カテゴリに応じて適切な価格を取得
          if cart_item.product.category == 'wott'
            # WOTT商品は全員一律でbase_price（1,100,000円）
            user_price = cart_item.product.base_price || 0
          else
            user_price = cart_item.product.price_for(current_user.level_symbol) || 0
          end
          
          purchase.purchase_items.create!(
            product: cart_item.product,
            quantity: cart_item.quantity,
            unit_price: user_price,
            seller_price: user_price  # 販売店の購入価格（同じ価格を設定）
          )
        end
        
        # 送料データを作成
        purchase.create_shipping_fees!

        # 配送情報を作成
        create_delivery_information(purchase)

        # 料金計算
        product_amount = purchase.total_price
        
        # 送料は自動的にShippingFeeレコードで管理されるため、合計を取得
        shipping_fee = purchase.total_shipping_fees
        
        # 商品別配送先判定（事務手数料計算用）
        purchase_items = purchase.purchase_items.includes(:product)
        has_bone_marrow_product = purchase_items.any? { |item| item.product.id == 1 }
        
        # 事務手数料（骨髄幹細胞培培養上清液の場合）
        admin_fee = has_bone_marrow_product ? 10000 : 0
        
        # 税抜き合計（商品代金+送料+事務手数料）
        subtotal_before_tax = product_amount + shipping_fee + admin_fee
        
        # 消費税計算
        tax_rate = ENV.fetch('TAX_RATE', '0.1').to_f
        tax_amount = (subtotal_before_tax * tax_rate).to_i
        
        # 税込み合計
        total_with_tax = subtotal_before_tax + tax_amount

        # 購入請求書を自動生成
        purchase_invoice = PurchaseInvoice.create!(
          purchase: purchase,
          invoice_number: PurchaseInvoice.generate_invoice_number,
          invoice_date: Date.current,
          due_date: Date.current + 1.week,
          total_amount: product_amount,
          shipping_fee: shipping_fee,
          admin_fee: admin_fee,
          tax_amount: tax_amount,
          tax_rate: tax_rate,
          subtotal_before_tax: subtotal_before_tax,
          total_with_tax: total_with_tax,
          status: PurchaseInvoice::SENT,
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