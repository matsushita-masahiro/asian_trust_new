class Admin::InvoiceStatusController < Admin::BaseController
  def index
    @selected_status = params[:status].presence || 'sent'
    
    status_value = case @selected_status
                  when 'sent' then Invoice::SENT
                  when 'confirmed' then Invoice::CONFIRMED
                  when 'receipt_requested' then Invoice::RECEIPT_REQUESTED
                  when 'draft' then Invoice::DRAFT
                  else Invoice::SENT
                  end
    
    @invoices = Invoice.includes(:user, :invoice_recipient)
                      .where(status: status_value)
                      .order(created_at: :desc)
  end

  def update_status
    @invoice = Invoice.find(params[:id])
    
    status_value = case params[:status]
                  when 'sent' then Invoice::SENT
                  when 'confirmed' then Invoice::CONFIRMED
                  when 'receipt_requested' then Invoice::RECEIPT_REQUESTED
                  when 'draft' then Invoice::DRAFT
                  else Invoice::SENT
                  end
    
    if @invoice.update(status: status_value)
      status_text = case params[:status]
                   when 'sent' then '送付済み'
                   when 'confirmed' then '振込確認済み'
                   when 'receipt_requested' then '領収書発行依頼済み'
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
end