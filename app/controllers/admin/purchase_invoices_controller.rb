class Admin::PurchaseInvoicesController < ApplicationController
  include ActionView::Helpers::NumberHelper
  
  before_action :authenticate_user!
  before_action :ensure_admin
  before_action :set_purchase_invoice, only: [:show, :edit, :update, :send_invoice, :confirm_payment, :send_receipt]

  def index
    @purchase_invoices = PurchaseInvoice.includes(:purchase => [:user, :purchase_items => :product])
                                       .order(created_at: :desc)
    
    # ステータスフィルター
    if params[:status].present?
      @purchase_invoices = @purchase_invoices.where(status: params[:status])
    end
  end

  def show
  end

  def new
    @purchase = Purchase.find(params[:purchase_id])
    
    # 既に請求書が存在する場合はリダイレクト
    if @purchase.purchase_invoice.present?
      redirect_to admin_purchase_invoice_path(@purchase.purchase_invoice), notice: "既に請求書が作成されています"
      return
    end
    
    @purchase_invoice = @purchase.build_purchase_invoice
    @purchase_invoice.invoice_number = PurchaseInvoice.generate_invoice_number
    @purchase_invoice.invoice_date = Date.current
    @purchase_invoice.due_date = Date.current + 1.week
    @purchase_invoice.total_amount = @purchase.total_price
  end

  def create
    @purchase = Purchase.find(params[:purchase_id])
    @purchase_invoice = @purchase.build_purchase_invoice(purchase_invoice_params)
    
    if @purchase_invoice.save
      redirect_to admin_purchase_invoice_path(@purchase_invoice), notice: '購入請求書が作成されました。'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @purchase_invoice.update(purchase_invoice_params)
      redirect_to admin_purchase_invoice_path(@purchase_invoice), notice: '購入請求書が更新されました。'
    else
      render :edit
    end
  end

  def send_invoice
    begin
      Rails.logger.info "Starting purchase invoice send process for PurchaseInvoice #{@purchase_invoice.id}"
      
      # PDF生成とS3アップロード
      pdf_service = PurchaseInvoicePdfService.new(@purchase_invoice)
      pdf_content = pdf_service.generate_and_upload_pdf
      
      # TODO: メール送信（PDFを添付）（後で実装）
      # PurchaseInvoiceMailer.send_invoice(@purchase_invoice, pdf_content).deliver_now
      
      # 送付処理
      @purchase_invoice.sent!
      
      Rails.logger.info "PurchaseInvoice #{@purchase_invoice.id} sent successfully"
      redirect_to admin_purchase_invoice_path(@purchase_invoice), notice: '購入請求書を送付しました。（PDF生成・メール送信は後で実装予定）'
      
    rescue => e
      Rails.logger.error "Purchase invoice send error: #{e.message}"
      redirect_to admin_purchase_invoice_path(@purchase_invoice), alert: "請求書の送付に失敗しました。エラー: #{e.message}"
    end
  end

  def confirm_payment
    # 送付済みの場合のみ支払い確認可能
    unless @purchase_invoice.sent?
      redirect_to admin_purchase_invoice_path(@purchase_invoice), alert: "送付済みの請求書のみ支払い確認できます"
      return
    end

    if @purchase_invoice.paid!
      # 購入ステータスも更新
      @purchase_invoice.purchase.update!(status: 'paid')
      redirect_to admin_purchase_invoice_path(@purchase_invoice), notice: '支払いを確認しました。'
    else
      redirect_to admin_purchase_invoice_path(@purchase_invoice), alert: '支払い確認に失敗しました。'
    end
  end

  def send_receipt
    Rails.logger.info "=== Admin send_receipt action called for PurchaseInvoice #{@purchase_invoice.id} ==="
    Rails.logger.info "PurchaseInvoice status: #{@purchase_invoice.status}"
    Rails.logger.info "PurchaseInvoice receipt_requested?: #{@purchase_invoice.receipt_requested?}"
    
    # 領収書発行依頼済みの場合のみ領収書発行可能
    unless @purchase_invoice.receipt_requested?
      Rails.logger.warn "Receipt not requested yet for PurchaseInvoice #{@purchase_invoice.id}"
      redirect_to admin_purchases_path, alert: '領収書発行依頼済みの請求書のみ領収書を発行できます。'
      return
    end

    begin
      Rails.logger.info "Starting purchase receipt generation for PurchaseInvoice #{@purchase_invoice.id}"
      
      # 領収書PDF生成とS3アップロード
      receipt_service = PurchaseReceiptPdfService.new(@purchase_invoice)
      pdf_content = receipt_service.generate_and_upload_pdf
      
      # 領収書発行完了ステータスに更新
      @purchase_invoice.receipt_sent!
      
      # 領収書発行通知を作成
      send_receipt_issued_notification(@purchase_invoice)
      
      # 領収書メール送信
      send_receipt_email(@purchase_invoice)
      
      Rails.logger.info "Purchase receipt #{@purchase_invoice.id} generated successfully"
      redirect_to admin_purchases_path, notice: '領収書を発行しました。'
    rescue => e
      Rails.logger.error "Purchase receipt generation error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      redirect_to admin_purchases_path, alert: "領収書の発行に失敗しました。エラー: #{e.message}"
    end
  end

  private

  def send_receipt_issued_notification(purchase_invoice)
    # 領収書発行通知の送信
    begin
      Rails.logger.info "Creating receipt issued notification for user #{purchase_invoice.purchase.user.id}"
      
      # 通知レコードの作成
      notification = Notification.create!(
        user: purchase_invoice.purchase.user,
        title: '領収書が発行されました',
        message: build_receipt_issued_message(purchase_invoice),
        notification_type: Notification::RECEIPT_ISSUED,
        link_url: purchase_invoice_path(purchase_invoice)
      )
      
      Rails.logger.info "Receipt issued notification created successfully: ID #{notification.id}, User: #{purchase_invoice.purchase.user.id}, Type: #{notification.notification_type}"
    rescue => e
      Rails.logger.error "Failed to send receipt issued notification: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
  
  def send_receipt_email(purchase_invoice)
    # 領収書メール送信
    begin
      Rails.logger.info "Sending receipt email for PurchaseInvoice #{purchase_invoice.id}"
      
      PurchaseReceiptMailer.send_receipt(purchase_invoice).deliver_now
      
      Rails.logger.info "Receipt email sent successfully for PurchaseInvoice #{purchase_invoice.id}"
    rescue => e
      Rails.logger.error "Failed to send receipt email: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end

  def build_receipt_issued_message(purchase_invoice)
    begin
      total_amount = purchase_invoice.total_with_tax || purchase_invoice.total_amount || 0
      product_names = purchase_invoice.purchase.purchase_items.map { |item| "#{item.product.name} × #{item.quantity}" }.join('、')
      
      "ご注文の商品の領収書が発行されました。\n" \
      "商品: #{product_names}\n" \
      "金額: ¥#{ActionController::Base.helpers.number_with_delimiter(total_amount)}\n" \
      "領収書PDFはメールに添付されています。"
    rescue => e
      Rails.logger.error "Error building receipt message: #{e.message}"
      "ご注文の商品の領収書が発行されました。詳細は購入詳細ページからご確認ください。"
    end
  end

  def set_purchase_invoice
    @purchase_invoice = PurchaseInvoice.find(params[:id])
  end

  def purchase_invoice_params
    params.require(:purchase_invoice).permit(:invoice_number, :invoice_date, :due_date, :total_amount, :notes)
  end

  def ensure_admin
    unless current_user&.level&.value == 0  # アジアビジネストラスト
      redirect_to root_path, alert: "管理者権限が必要です"
    end
  end
end