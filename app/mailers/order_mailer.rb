class OrderMailer < ApplicationMailer
  default from: ENV['ADMIN_EMAIL'] || 'noreply@example.com'

  def bank_transfer_instructions(purchase, purchase_invoice = nil)
    @purchase = purchase
    @user = purchase.buyer
    @total_amount = purchase.total_price
    @purchase_items = purchase.purchase_items.includes(:product)
    @purchase_invoice = purchase_invoice
    
    Rails.logger.info "Preparing bank transfer email for purchase #{@purchase.id}"
    Rails.logger.info "User email: #{@user.email}"
    Rails.logger.info "Purchase invoice present: #{@purchase_invoice.present?}"
    
    # 購入請求書HTMLを添付
    if @purchase_invoice
      begin
        Rails.logger.info "Starting HTML invoice generation for invoice #{@purchase_invoice.invoice_number}"
        
        # HTMLテンプレートをレンダリング
        html_content = render_to_string(
          template: 'order_mailer/invoice_pdf',
          layout: false,
          locals: { purchase_invoice: @purchase_invoice }
        )
        
        Rails.logger.info "HTML content generated, size: #{html_content.bytesize} bytes"
        
        # HTMLファイルとして添付
        attachments["請求書_#{@purchase_invoice.invoice_number}.html"] = {
          mime_type: 'text/html',
          content: html_content
        }
        
        Rails.logger.info "HTML invoice attachment added successfully"
        
      rescue => e
        Rails.logger.error "Failed to generate HTML invoice: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        # HTMLが生成できなくてもメールは送信する
      end
    else
      Rails.logger.warn "No purchase_invoice provided for email attachment"
    end
    
    Rails.logger.info "Sending bank transfer email..."
    
    mail(
      to: @user.email,
      subject: "【Asia Business Trust】銀行振込のご案内・請求書 - 注文番号: ##{@purchase.id}"
    )
  end

  def payment_confirmed(purchase)
    @purchase = purchase
    @user = purchase.buyer
    @total_amount = purchase.total_price
    @purchase_items = purchase.purchase_items.includes(:product)
    
    # 一時的な修正: Purchase ID 22の場合は正しいメールアドレスに送信
    recipient_email = if purchase.id == 22
                       'mmatsu3737+10@gmail.com'
                     else
                       @user.email
                     end
    
    mail(
      to: recipient_email,
      subject: "【Asia Business Trust】入金確認のお知らせ - 注文番号: ##{@purchase.id}"
    )
  end

  private
end