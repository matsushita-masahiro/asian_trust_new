class Admin::InvoiceStatusController < Admin::BaseController
  def index
    @selected_status = params[:status].presence || 'sent'
    
    status_value = case @selected_status
                  when 'sent' then Invoice::SENT
                  when 'confirmed' then Invoice::CONFIRMED
                  when 'receipt_requested' then Invoice::RECEIPT_REQUESTED
                  when 'receipt_sent' then Invoice::RECEIPT_SENT
                  when 'draft' then Invoice::DRAFT
                  else Invoice::SENT
                  end
    
    @invoices = Invoice.includes(:user, :invoice_recipient)
                      .where(status: status_value)
                      .order(created_at: :desc)
  end

  def show_receipt
    @invoice = Invoice.find(params[:id])
    
    # 領収書発行依頼済みのみ表示可能
    unless @invoice.receipt_requested?
      redirect_to admin_invoice_status_index_path, 
                  alert: '領収書発行依頼済みの請求書のみ表示できます。'
      return
    end
    
    # インセンティブの詳細情報を取得
    @incentive_details = @invoice.user.monthly_incentive_with_details(@invoice.target_month)
  end

  def send_receipt
    @invoice = Invoice.find(params[:id])
    
    # 領収書発行依頼済みのみ送信可能
    unless @invoice.receipt_requested?
      redirect_to admin_invoice_status_index_path, 
                  alert: '領収書発行依頼済みの請求書のみ送信できます。'
      return
    end

    begin
      # 領収書メール送信
      ReceiptMailer.send_receipt(@invoice).deliver_now
      
      # ステータスを領収書発行完了に変更
      @invoice.receipt_sent!
      
      redirect_to admin_invoice_status_index_path(status: 'receipt_requested'), 
                  notice: '領収書を送信しました。'
    rescue => e
      Rails.logger.error "領収書送信エラー: #{e.message}"
      redirect_to show_receipt_admin_invoice_status_path(@invoice), 
                  alert: '領収書の送信に失敗しました。'
    end
  end

  def update_status
    @invoice = Invoice.find(params[:id])
    
    status_value = case params[:status]
                  when 'sent' then Invoice::SENT
                  when 'confirmed' then Invoice::CONFIRMED
                  when 'receipt_requested' then Invoice::RECEIPT_REQUESTED
                  when 'receipt_sent' then Invoice::RECEIPT_SENT
                  when 'draft' then Invoice::DRAFT
                  else Invoice::SENT
                  end
    
    if @invoice.update(status: status_value)
      status_text = case params[:status]
                   when 'sent' then '送付済み'
                   when 'confirmed' then '振込確認済み'
                   when 'receipt_requested' then '領収書発行依頼済み'
                   when 'receipt_sent' then '領収書発行完了'
                   when 'draft' then '下書き'
                   else params[:status]
                   end
      redirect_to admin_invoice_status_index_path(status: params[:status]), 
                  notice: "請求書のステータスを#{status_text}に更新しました。"
    else
      redirect_to admin_invoice_status_index_path, 
                  alert: 'ステータスの更新に失敗しました。'
    end
  end

  def issue_receipt
    @invoice = Invoice.find(params[:id])
    
    # 領収書発行依頼済みのもののみ処理可能
    unless @invoice.receipt_requested?
      redirect_to admin_invoice_status_index_path, alert: '領収書発行依頼済みの請求書のみ処理できます。'
      return
    end

    # 領収書発行処理（実際の実装に応じて調整）
    begin
      # ここで領収書PDF生成やメール送信などの処理を行う
      # 例: ReceiptMailer.send_receipt(@invoice).deliver_now
      
      # sent_atをクリアして「振込確認済み」状態に戻す（または別の状態管理）
      @invoice.update!(sent_at: nil)
      
      redirect_to admin_invoice_status_index_path(status: 'confirmed'), 
                  notice: '領収書を発行しました。'
    rescue => e
      Rails.logger.error "領収書発行エラー: #{e.message}"
      redirect_to admin_invoice_status_index_path(status: 'receipt_requested'), 
                  alert: '領収書の発行に失敗しました。'
    end
  end
end