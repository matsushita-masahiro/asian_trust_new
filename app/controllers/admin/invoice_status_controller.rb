class Admin::InvoiceStatusController < Admin::BaseController
  def index
    @selected_status = params[:status].presence || 'sent'
    @search_invoice_number = params[:search_invoice_number]
    @search_user_name = params[:search_user_name]
    @search_target_month = params[:search_target_month]
    
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
    
    # 請求書番号での検索（一部一致）
    if @search_invoice_number.present?
      @invoices = @invoices.where("invoice_number LIKE ?", "%#{@search_invoice_number}%")
    end
    
    # 請求者名での検索（一部一致）
    if @search_user_name.present?
      @invoices = @invoices.joins(:user).where("users.name LIKE ? OR users.email LIKE ?", "%#{@search_user_name}%", "%#{@search_user_name}%")
    end
    
    # 対象年月での検索（完全一致または部分一致）
    if @search_target_month.present?
      @invoices = @invoices.where("target_month LIKE ?", "%#{@search_target_month}%")
    end
    
    @invoices = @invoices.order(created_at: :desc)
  end

  def show_receipt
    @invoice = Invoice.find(params[:id])
    
    # 領収書PDFが存在するかチェック
    unless @invoice.receipt_file.attached?
      redirect_to admin_invoice_status_index_path, 
                  alert: '領収書PDFが見つかりません。'
      return
    end
    
    # S3にファイルが実際に存在するかチェック
    begin
      if @invoice.receipt_file.blob.service.exist?(@invoice.receipt_file.blob.key)
        # PDFの内容を取得して表示
        respond_to do |format|
          format.html { redirect_to rails_blob_path(@invoice.receipt_file, disposition: "inline") }
          format.pdf { redirect_to rails_blob_path(@invoice.receipt_file, disposition: "attachment") }
        end
      else
        redirect_to admin_invoice_status_index_path, 
                    alert: '領収書PDFファイルがS3に存在しません。'
      end
    rescue => e
      Rails.logger.error "Receipt PDF access error: #{e.message}"
      redirect_to admin_invoice_status_index_path, 
                  alert: '領収書PDFの取得に失敗しました。'
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
      # 振込完了時にメール送信と通知作成
      if params[:status] == 'confirmed'
        begin
          # メール送信
          InvoiceMailer.payment_completed(@invoice).deliver_now
          Rails.logger.info "振込完了メール送信成功: #{@invoice.invoice_number} to #{@invoice.user.email}"
          
          # 通知作成
          @invoice.user.notifications.create!(
            notification_type: Notification::INCENTIVE_PAYMENT_COMPLETED,
            title: 'インセンティブ振込完了',
            message: "請求書#{@invoice.invoice_number}のインセンティブが振込まれました。金額: ¥#{ActionController::Base.helpers.number_with_delimiter(@invoice.total_amount)}",
            link_url: Rails.application.routes.url_helpers.history_invoices_path
          )
          Rails.logger.info "振込完了通知作成成功: #{@invoice.invoice_number} for user #{@invoice.user.id}"
        rescue => e
          Rails.logger.error "振込完了処理エラー: #{e.message}"
        end
      end
      
      # 領収書発行依頼時にメール送信と通知作成
      if params[:status] == 'receipt_requested'
        begin
          # メール送信
          InvoiceMailer.receipt_request(@invoice).deliver_now
          Rails.logger.info "領収書発行依頼メール送信成功: #{@invoice.invoice_number} to #{@invoice.user.email}"
          
          # 同じ請求書に対する領収書発行依頼通知が既に存在するかチェック
          existing_notification = @invoice.user.notifications.find_by(
            notification_type: Notification::RECEIPT_REQUEST,
            message: "請求書#{@invoice.invoice_number}の領収書発行手続きをお願いします。"
          )
          
          # 既存の通知がない場合のみ新しい通知を作成
          unless existing_notification
            @invoice.user.notifications.create!(
              notification_type: Notification::RECEIPT_REQUEST,
              title: '領収書発行依頼',
              message: "請求書#{@invoice.invoice_number}の領収書発行手続きをお願いします。",
              link_url: Rails.application.routes.url_helpers.history_invoices_path
            )
            Rails.logger.info "領収書発行依頼通知作成成功: #{@invoice.invoice_number} for user #{@invoice.user.id}"
          else
            Rails.logger.info "領収書発行依頼通知は既に存在: #{@invoice.invoice_number} for user #{@invoice.user.id}"
          end
        rescue => e
          Rails.logger.error "領収書発行依頼処理エラー: #{e.message}"
        end
      end
      
      status_text = case params[:status]
                   when 'sent' then '送付済み'
                   when 'confirmed' then '振込確認済み'
                   when 'receipt_requested' then '領収書発行依頼済み'
                   when 'receipt_sent' then '領収書発行完了'
                   when 'draft' then '下書き'
                   else params[:status]
                   end
      # 元のフィルター状態を保持してリダイレクト
      original_status = params[:original_status] || 'sent'
      
      notice_message = if params[:status] == 'confirmed'
        "請求書#{@invoice.invoice_number}のステータスを#{status_text}に更新し、振込完了メールを送信しました。"
      elsif params[:status] == 'receipt_requested'
        "請求書#{@invoice.invoice_number}のステータスを#{status_text}に更新し、領収書発行依頼メールを送信しました。"
      else
        "請求書#{@invoice.invoice_number}のステータスを#{status_text}に更新しました。"
      end
      
      redirect_to admin_invoice_status_index_path(status: original_status), 
                  notice: notice_message
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