class PurchaseInvoicesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_purchase_invoice, only: [:show, :edit, :update, :send_invoice, :confirm_payment, :request_receipt, :send_receipt]

  def index
    # 購入者として受け取った請求書一覧
    @purchase_invoices = PurchaseInvoice.joins(:purchase)
                                       .where(purchases: { user_id: current_user.id })
                                       .includes(:purchase => [:user, :purchase_items => :product])
                                       .order(created_at: :desc)
  end

  def show
    # 購入者または販売者のみアクセス可能
    unless can_access_purchase_invoice?
      redirect_to root_path, alert: "アクセス権がありません"
      return
    end
    
    # user_id=1のInvoiceRecipientから振込口座情報を取得
    @bank_info = InvoiceRecipient.find_by(user_id: 1)
  end

  def new
    @purchase = Purchase.find(params[:purchase_id])
    
    # 既に請求書が存在する場合はリダイレクト
    if @purchase.purchase_invoice.present?
      redirect_to purchase_invoice_path(@purchase.purchase_invoice), notice: "既に請求書が作成されています"
      return
    end
    
    @purchase_invoice = @purchase.build_purchase_invoice
    @purchase_invoice.invoice_number = PurchaseInvoice.generate_invoice_number
    @purchase_invoice.invoice_date = Date.current
    @purchase_invoice.due_date = @purchase.purchased_at.to_date + 1.week
    @purchase_invoice.total_amount = @purchase.total_price
    @purchase_invoice.status = PurchaseInvoice::DRAFT
  end

  def create
    @purchase = Purchase.find(params[:purchase_id])
    @purchase_invoice = @purchase.build_purchase_invoice(purchase_invoice_params)
    @purchase_invoice.status = PurchaseInvoice::DRAFT
    
    if @purchase_invoice.save
      redirect_to purchase_invoice_path(@purchase_invoice), notice: '購入請求書が作成されました。'
    else
      render :new
    end
  end

  def edit
    # 下書きまたは送付済みの場合のみ編集可能
    unless @purchase_invoice.draft? || @purchase_invoice.sent?
      redirect_to purchase_invoice_path(@purchase_invoice), alert: "この請求書は編集できません"
      return
    end
  end

  def update
    if @purchase_invoice.update(purchase_invoice_params)
      redirect_to purchase_invoice_path(@purchase_invoice), notice: '購入請求書が更新されました。'
    else
      render :edit
    end
  end

  def send_invoice
    # 管理者のみ実行可能
    unless current_user.level&.value == 0  # アジアビジネストラスト
      redirect_to purchase_invoice_path(@purchase_invoice), alert: "権限がありません"
      return
    end

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
      redirect_to purchase_invoice_path(@purchase_invoice), notice: '購入請求書を送付しました。（PDF生成・メール送信は後で実装予定）'
      
    rescue => e
      Rails.logger.error "Purchase invoice send error: #{e.message}"
      redirect_to purchase_invoice_path(@purchase_invoice), alert: "請求書の送付に失敗しました。エラー: #{e.message}"
    end
  end

  def confirm_payment
    # 管理者のみ実行可能
    unless current_user.level&.value == 0  # アジアビジネストラスト
      redirect_to purchase_invoice_path(@purchase_invoice), alert: "権限がありません"
      return
    end

    # 送付済みの場合のみ支払い確認可能
    unless @purchase_invoice.sent?
      redirect_to purchase_invoice_path(@purchase_invoice), alert: "送付済みの請求書のみ支払い確認できます"
      return
    end

    if @purchase_invoice.paid!
      # 購入ステータスも更新
      @purchase_invoice.purchase.update!(status: 'paid')
      redirect_to purchase_invoice_path(@purchase_invoice), notice: '支払いを確認しました。'
    else
      redirect_to purchase_invoice_path(@purchase_invoice), alert: '支払い確認に失敗しました。'
    end
  end

  def request_receipt
    # 支払い完了済みの場合のみ領収書発行依頼可能
    unless @purchase_invoice.paid?
      redirect_to purchase_invoice_path(@purchase_invoice), alert: '支払い完了済みの請求書のみ領収書発行依頼できます。'
      return
    end

    # 既に依頼済みの場合
    if @purchase_invoice.receipt_requested?
      redirect_to purchase_invoice_path(@purchase_invoice), alert: '既に領収書発行を依頼済みです。'
      return
    end

    if @purchase_invoice.receipt_requested!
      redirect_to purchase_invoice_path(@purchase_invoice), notice: '領収書発行を依頼しました。管理者が確認後、領収書を発行いたします。'
    else
      redirect_to purchase_invoice_path(@purchase_invoice), alert: '領収書発行依頼に失敗しました。'
    end
  end

  def send_receipt
    # 管理者のみ実行可能
    unless current_user.level&.value == 0  # アジアビジネストラスト
      redirect_to purchase_invoice_path(@purchase_invoice), alert: "権限がありません"
      return
    end

    # 領収書発行依頼済みの場合のみ領収書発行可能
    unless @purchase_invoice.receipt_requested?
      redirect_to purchase_invoice_path(@purchase_invoice), alert: '領収書発行依頼済みの請求書のみ領収書を発行できます。'
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
      redirect_to purchase_invoice_path(@purchase_invoice), notice: '領収書を発行しました。（PDF生成は後で実装予定）'
    rescue => e
      Rails.logger.error "Purchase receipt generation error: #{e.message}"
      redirect_to purchase_invoice_path(@purchase_invoice), alert: "領収書の発行に失敗しました。エラー: #{e.message}"
    end
  end

  private

  def set_purchase_invoice
    @purchase_invoice = PurchaseInvoice.find(params[:id])
  end

  def purchase_invoice_params
    params.require(:purchase_invoice).permit(:invoice_number, :invoice_date, :due_date, :total_amount, :notes)
  end

  def can_access_purchase_invoice?
    # 購入者または管理者のみアクセス可能
    @purchase_invoice.purchase.user == current_user || 
    current_user.level&.value == 0  # アジアビジネストラスト
  end
end