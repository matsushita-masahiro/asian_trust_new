class InvoicesController < ApplicationController
  before_action :authenticate_user!

  def index
    # 請求書管理のメインページ
  end

  def history
    # 請求書履歴
    @invoices = current_user.invoices.includes(:invoice_recipient).order(created_at: :desc)
  end

  def issue
    # 請求書発行
    @invoice = current_user.invoices.build
    @invoice_recipients = InvoiceRecipient.all
    
    # 該当月の設定（パラメータから取得、なければ今月）
    @selected_month = params[:month].presence || Date.current.strftime("%Y-%m")
    @selected_month_start = Date.strptime(@selected_month, "%Y-%m").beginning_of_month
    @selected_month_end = Date.strptime(@selected_month, "%Y-%m").end_of_month
    
    # 該当月のボーナス合計額を計算
    @total_bonus = current_user.bonus_in_month(@selected_month)
    @invoice.total_amount = @total_bonus.to_i
    
    # ボーナス内訳を取得
    @bonus_details = get_bonus_details(@selected_month_start, @selected_month_end)
    
    # デバッグ情報
    Rails.logger.info "=== Invoice Issue Debug ==="
    Rails.logger.info "Selected month: #{@selected_month}"
    Rails.logger.info "Date range: #{@selected_month_start} to #{@selected_month_end}"
    Rails.logger.info "Total bonus: #{@total_bonus}"
    Rails.logger.info "Bonus details count: #{@bonus_details.count}"
    Rails.logger.info "User purchases count: #{current_user.purchases.where(purchased_at: @selected_month_start..@selected_month_end).count}"
    Rails.logger.info "Descendant purchases count: #{Purchase.where(user_id: current_user.descendant_ids, purchased_at: @selected_month_start..@selected_month_end).count}"
    Rails.logger.info "Current user level: #{current_user.level&.name}"
    Rails.logger.info "Current user descendant_ids: #{current_user.descendant_ids}"
    
    # 既存のInvoiceBaseから振込先情報を取得
    @existing_invoice_base = current_user.invoice_base
    if @existing_invoice_base
      # 既存データがある場合は初期値として設定
      @invoice.bank_name = @existing_invoice_base.bank_name
      @invoice.bank_branch_name = @existing_invoice_base.bank_branch_name
      @invoice.bank_account_type = @existing_invoice_base.bank_account_type
      @invoice.bank_account_number = @existing_invoice_base.bank_account_number
      @invoice.bank_account_name = @existing_invoice_base.bank_account_name
    end
    
    # 請求先が設定されていない場合の警告
    if @invoice_recipients.empty?
      flash.now[:warning] = "請求先情報が設定されていません。先に請求書情報設定で請求先を登録してください。"
    end
  end

  def settings
    if request.post?
      # 請求元情報（invoice_base）を作成または更新
      @invoice_base = current_user.invoice_base || current_user.build_invoice_base
      
      if @invoice_base.update(invoice_base_params)
        redirect_to settings_invoices_path, notice: '請求元情報が保存されました。'
        return
      else
        flash.now[:error] = '請求元情報の保存に失敗しました。'
      end
    else
      @invoice_base = current_user.invoice_base || current_user.build_invoice_base
    end
  end

  def show
    @invoice = current_user.invoices.includes(:invoice_recipient).find(params[:id])
    
    # 請求書のtarget_monthを使用（invoice_dateではなく）
    @selected_month = @invoice.target_month || Date.current.strftime("%Y-%m")
    @selected_month_start = Date.strptime(@selected_month, "%Y-%m").beginning_of_month
    @selected_month_end = Date.strptime(@selected_month, "%Y-%m").end_of_month
    
    # ボーナス内訳を取得
    @bonus_details = get_bonus_details(@selected_month_start, @selected_month_end)
    @total_bonus = current_user.bonus_in_month(@selected_month)
    
    # デバッグ情報
    Rails.logger.info "=== Invoice Show Debug ==="
    Rails.logger.info "Invoice ID: #{@invoice.id}"
    Rails.logger.info "Target month: #{@invoice.target_month}"
    Rails.logger.info "Selected month: #{@selected_month}"
    Rails.logger.info "Date range: #{@selected_month_start} to #{@selected_month_end}"
    Rails.logger.info "Total bonus: #{@total_bonus}"
    Rails.logger.info "Bonus details count: #{@bonus_details.count}"
  end

  def new
    @invoice = current_user.invoices.build
    @invoice_recipients = current_user.invoice_recipients
  end

  def create
    @invoice = current_user.invoices.build(invoice_params)
    @invoice.status = Invoice::DRAFT  # 作成時は下書き状態
    
    # デバッグ情報をログに出力
    Rails.logger.info "Invoice params: #{invoice_params.inspect}"
    Rails.logger.info "Invoice valid?: #{@invoice.valid?}"
    Rails.logger.info "Invoice errors: #{@invoice.errors.full_messages}" unless @invoice.valid?
    
    if @invoice.save
      redirect_to invoice_path(@invoice), notice: '請求書が作成されました。確認後に請求書を送付してください。'
    else
      @invoice_recipients = InvoiceRecipient.all
      # エラー時に必要な変数を再設定
      @selected_month = @invoice.target_month || params[:month].presence || Date.current.strftime("%Y-%m")
      @selected_month_start = Date.strptime(@selected_month, "%Y-%m").beginning_of_month
      @selected_month_end = Date.strptime(@selected_month, "%Y-%m").end_of_month
      @total_bonus = current_user.bonus_in_month(@selected_month)
      @bonus_details = get_bonus_details(@selected_month_start, @selected_month_end)
      
      # エラーメッセージをフラッシュに追加
      flash.now[:error] = "請求書の作成に失敗しました: #{@invoice.errors.full_messages.join(', ')}"
      render :issue
    end
  end

  def edit
    @invoice = current_user.invoices.find(params[:id])
    @invoice_recipients = InvoiceRecipient.all
    
    # 請求書のtarget_monthを使用（invoice_dateではなく）
    @selected_month = @invoice.target_month || Date.current.strftime("%Y-%m")
    @selected_month_start = Date.strptime(@selected_month, "%Y-%m").beginning_of_month
    @selected_month_end = Date.strptime(@selected_month, "%Y-%m").end_of_month
    
    # ボーナス内訳を取得
    @bonus_details = get_bonus_details(@selected_month_start, @selected_month_end)
    @total_bonus = current_user.bonus_in_month(@selected_month)
  end

  def update
    @invoice = current_user.invoices.find(params[:id])
    
    if @invoice.update(invoice_params)
      redirect_to invoice_path(@invoice), notice: '請求書が更新されました。'
    else
      @invoice_recipients = InvoiceRecipient.all
      render :edit
    end
  end

  def send_invoice
    @invoice = current_user.invoices.find(params[:id])
    
    # 既に送付済みの場合は再送付として処理
    is_resend = @invoice.sent?
    
    begin
      Rails.logger.info "Starting invoice send process for Invoice #{@invoice.id}"
      
      # PDF生成とS3アップロード
      pdf_service = InvoicePdfService.new(@invoice)
      Rails.logger.info "Generating PDF for Invoice #{@invoice.id}"
      pdf_content = pdf_service.generate_and_upload_pdf
      Rails.logger.info "PDF generated and uploaded successfully for Invoice #{@invoice.id}"
      
      # メール送信（PDFを添付）
      Rails.logger.info "Sending email for Invoice #{@invoice.id}"
      InvoiceMailer.send_invoice(@invoice, pdf_content).deliver_now
      Rails.logger.info "Email sent successfully for Invoice #{@invoice.id}"
      
      # 送付処理（初回送付の場合のみステータス更新）
      unless is_resend
        @invoice.update!(sent_at: Time.current, status: Invoice::SENT)
        Rails.logger.info "Invoice #{@invoice.id} status updated to SENT"
      else
        @invoice.update!(sent_at: Time.current)
        Rails.logger.info "Invoice #{@invoice.id} resent, sent_at updated"
      end
      
      Rails.logger.info "Invoice #{@invoice.id} sent successfully with PDF uploaded to S3"
      
      message = is_resend ? '請求書を再送付しました。PDFは保存されました。' : '請求書を送付しました。PDFは保存されました。'
      redirect_to invoice_path(@invoice), notice: message
      
    rescue => e
      Rails.logger.error "Invoice send error for Invoice #{@invoice.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # エラーの詳細をログに記録
      if e.message.include?('S3')
        Rails.logger.error "S3 upload failed for Invoice #{@invoice.id}"
      elsif e.message.include?('PDF')
        Rails.logger.error "PDF generation failed for Invoice #{@invoice.id}"
      elsif e.message.include?('Mail')
        Rails.logger.error "Email sending failed for Invoice #{@invoice.id}"
      end
      
      redirect_to invoice_path(@invoice), alert: "請求書の送付に失敗しました。エラー: #{e.message}"
    end
  end

  def receipt
    @invoice = current_user.invoices.find(params[:id])
    
    # 確認済みステータスのみ領収書発行可能
    unless @invoice.confirmed?
      redirect_to history_invoices_path, alert: '確認済みの請求書のみ領収書を発行できます。'
      return
    end
    
    # target_monthのボーナス詳細を取得
    if @invoice.target_month.present?
      selected_month_start = Date.strptime(@invoice.target_month, "%Y-%m").beginning_of_month
      selected_month_end = Date.strptime(@invoice.target_month, "%Y-%m").end_of_month
      @bonus_details = get_bonus_details(selected_month_start, selected_month_end)
    end
  end

  def request_receipt
    @invoice = current_user.invoices.find(params[:id])
    
    # 確認済みステータスのみ領収書発行依頼可能
    unless @invoice.confirmed?
      redirect_to history_invoices_path, alert: '確認済みの請求書のみ領収書発行依頼できます。'
      return
    end

    # 既に依頼済みの場合
    if @invoice.receipt_requested?
      redirect_to history_invoices_path, alert: '既に領収書発行を依頼済みです。'
      return
    end

    # 領収書発行依頼（sent_atを設定）
    if @invoice.request_receipt!
      redirect_to history_invoices_path, notice: '領収書発行を依頼しました。管理者が確認後、領収書を発行いたします。'
    else
      redirect_to history_invoices_path, alert: '領収書発行依頼に失敗しました。'
    end
  end

  def send_receipt
    @invoice = current_user.invoices.find(params[:id])
    
    # 領収書発行依頼済みステータスのみ領収書発行可能
    unless @invoice.receipt_requested?
      redirect_to history_invoices_path, alert: '領収書発行依頼済みの請求書のみ領収書を発行できます。'
      return
    end

    begin
      Rails.logger.info "Starting receipt generation for Invoice #{@invoice.id}"
      
      # 領収書PDF生成とS3アップロード
      receipt_service = ReceiptPdfService.new(@invoice)
      Rails.logger.info "ReceiptPdfService initialized for Invoice #{@invoice.id}"
      
      pdf_content = receipt_service.generate_and_upload_pdf
      Rails.logger.info "Receipt PDF generated and uploaded for Invoice #{@invoice.id}"
      
      # 領収書発行完了ステータスに更新
      @invoice.receipt_sent!
      Rails.logger.info "Invoice #{@invoice.id} status updated to receipt_sent"
      
      Rails.logger.info "Receipt #{@invoice.id} generated successfully with PDF uploaded to S3"
      redirect_to history_invoices_path, notice: '領収書を発行しました。PDFは保存されました。'
    rescue => e
      Rails.logger.error "Receipt generation error for Invoice #{@invoice.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # エラーの詳細をログに記録
      if e.message.include?('S3')
        Rails.logger.error "S3 upload failed for Receipt #{@invoice.id}"
      elsif e.message.include?('PDF')
        Rails.logger.error "PDF generation failed for Receipt #{@invoice.id}"
      elsif e.message.include?('template')
        Rails.logger.error "Template rendering failed for Receipt #{@invoice.id}"
      end
      
      redirect_to history_invoices_path, alert: "領収書の発行に失敗しました。エラー: #{e.message}"
    end
  end

  private

  def invoice_params
    params.require(:invoice).permit(:invoice_date, :due_date, :total_amount, :bank_name, :bank_branch_name, :bank_account_type, :bank_account_number, :bank_account_name, :notes, :sent_at, :invoice_recipient_id, :target_month)
  end

  def invoice_recipient_params
    params.require(:invoice_recipient).permit(:name, :email, :postal_code, :address, :tel, :department, :notes)
  end

  def invoice_base_params
    params.require(:invoice_base).permit(:company_name, :postal_code, :address, :department, :email, :notes, :bank_name, :bank_branch_name, :bank_account_type, :bank_account_number, :bank_account_name)
  end

  def get_bonus_details(start_date, end_date)
    details = []
    
    Rails.logger.info "=== get_bonus_details Debug ==="
    Rails.logger.info "Date range: #{start_date} to #{end_date}"
    
    # 自分の販売に対するボーナス
    self_purchases = current_user.purchases.includes(purchase_items: :product).where(purchased_at: start_date..end_date)
    Rails.logger.info "Self purchases found: #{self_purchases.count}"
    
    self_purchases.each do |purchase|
      purchase.purchase_items.each do |item|
        bonus = current_user.bonus_for_purchase_item(item)
        
        Rails.logger.info "Purchase Item: #{item.product.name}, bonus: #{bonus}"
        
        if bonus > 0
          details << {
            type: '自己販売',
            user_name: current_user.name || current_user.email,
            product_name: item.product.name,
            quantity: item.quantity,
            unit_bonus: bonus / item.quantity,
            total_bonus: bonus,
            purchased_at: purchase.purchased_at
          }
        end
      end
    end
    
    # 子孫の販売に対するボーナス
    descendant_user_ids = current_user.descendant_ids.reject { |uid| uid == current_user.id }
    
    if descendant_user_ids.any?
      descendant_purchase_items = PurchaseItem.joins(:purchase)
                                             .where(purchases: { user_id: descendant_user_ids, purchased_at: start_date..end_date })
                                             .includes(:product, purchase: :user)
      
      Rails.logger.info "Descendant purchase items found: #{descendant_purchase_items.count}"
      
      descendant_purchase_items.each do |item|
        purchase = item.purchase
        purchase_user_level = purchase.user.level_at(purchase.purchased_at)
        my_level_at_purchase = current_user.level_at(purchase.purchased_at)
        
        product = item.product
        purchase_user_price = product.product_prices.find_by(level_id: purchase_user_level.id)&.price || 0
        my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
        
        if purchase_user_price > my_price
          diff = purchase_user_price - my_price
          bonus = diff * item.quantity
          
          Rails.logger.info "Descendant purchase item: #{item.product.name} by #{purchase.user.name}, bonus: #{bonus}"
          
          if bonus > 0
            details << {
              type: '下位販売',
              user_name: purchase.user.name || purchase.user.email,
              product_name: item.product.name,
              quantity: item.quantity,
              unit_bonus: diff,
              total_bonus: bonus,
              purchased_at: purchase.purchased_at
            }
          end
        end
      end
    end
    
    # 直下の無資格者による販売に対するボーナス
    descendant_user_ids_set = Set.new(current_user.descendant_ids)
    
    current_user.referrals.reject(&:bonus_eligible?).each do |child|
      # 既に子孫として計算済みの場合はスキップ
      next if descendant_user_ids_set.include?(child.id)
      
      child_purchase_items = PurchaseItem.joins(:purchase)
                                        .where(purchases: { user_id: child.id, purchased_at: start_date..end_date })
                                        .includes(:product, purchase: :user)
      
      child_purchase_items.each do |item|
        purchase_date = item.purchase.purchased_at
        my_level_at_purchase = current_user.level_at(purchase_date)
        product = item.product
        base_price = product.base_price
        my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
        diff = base_price - my_price
        bonus = diff * item.quantity
        
        if bonus > 0
          details << {
            type: '無資格者販売',
            user_name: child.name || child.email,
            product_name: item.product.name,
            quantity: item.quantity,
            unit_bonus: diff,
            total_bonus: bonus,
            purchased_at: purchase_date
          }
        end
      end
    end
    
    # 日付順でソート
    sorted_details = details.sort_by { |d| d[:purchased_at] }
    
    Rails.logger.info "Final bonus details count: #{sorted_details.count}"
    Rails.logger.info "Total bonus from details: #{sorted_details.sum { |d| d[:total_bonus] }}"
    Rails.logger.info "=== End get_bonus_details Debug ==="
    
    sorted_details
  end
end