class Admin::PurchaseInvoicesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin
  before_action :set_purchase_invoice, only: [:show, :edit, :update, :send_invoice, :confirm_payment, :send_receipt]

  def index
    @purchase_invoices = PurchaseInvoice.includes(:purchase => [:buyer, :user, :purchase_items => :product])
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
    @purchase_invoice.due_date = Date.current + 30.days
    @purchase_invoice.total_amount = @purchase.total_price
    @purchase_invoice.status = PurchaseInvoice::DRAFT
  end

  def create
    @purchase = Purchase.find(params[:purchase_id])
    @purchase_invoice = @purchase.build_purchase_invoice(purchase_invoice_params)
    @purchase_invoice.status = PurchaseInvoice::DRAFT
    
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
      
      # TODO: PDF生成とS3アップロード（後で実装）
      # pdf_service = PurchaseInvoicePdfService.new(@purchase_invoice)
      # pdf_content = pdf_service.generate_and_upload_pdf
      
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
    # 領収書発行依頼済みの場合のみ領収書発行可能
    unless @purchase_invoice.receipt_requested?
      redirect_to admin_purchase_invoice_path(@purchase_invoice), alert: '領収書発行依頼済みの請求書のみ領収書を発行できます。'
      return
    end

    begin
      Rails.logger.info "Starting purchase receipt generation for PurchaseInvoice #{@purchase_invoice.id}"
      
      # TODO: 領収書PDF生成とS3アップロード（後で実装）
      # receipt_service = PurchaseReceiptPdfService.new(@purchase_invoice)
      # pdf_content = receipt_service.generate_and_upload_pdf
      
      # 領収書発行完了ステータスに更新
      @purchase_invoice.receipt_sent!
      
      Rails.logger.info "Purchase receipt #{@purchase_invoice.id} generated successfully"
      redirect_to admin_purchase_invoice_path(@purchase_invoice), notice: '領収書を発行しました。（PDF生成は後で実装予定）'
    rescue => e
      Rails.logger.error "Purchase receipt generation error: #{e.message}"
      redirect_to admin_purchase_invoice_path(@purchase_invoice), alert: "領収書の発行に失敗しました。エラー: #{e.message}"
    end
  end

  private

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