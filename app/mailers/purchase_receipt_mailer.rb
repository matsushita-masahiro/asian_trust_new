# app/mailers/purchase_receipt_mailer.rb
class PurchaseReceiptMailer < ApplicationMailer
  def send_receipt(purchase_invoice)
    @purchase_invoice = purchase_invoice
    @purchase = purchase_invoice.purchase
    @user = @purchase.user
    @invoice_recipient = InvoiceRecipient.first
    
    Rails.logger.info "💌 Sending purchase receipt to: #{@user.email}"
    
    # 領収書PDFを添付
    attach_receipt_pdf
    
    # メール送信
    mail(
      from: ENV['ADMIN_EMAIL'] || 'info@abt-saisei.com',
      to: @user.email,
      subject: "【領収書発行】購入ID: #{@purchase.id} の領収書"
    )
  rescue => e
    Rails.logger.error("❌ PurchaseReceiptMailer#send_receipt failed: #{e.class} #{e.message}")
    raise
  end

  private

  def attach_receipt_pdf
    # 領収書PDF生成サービスを使用
    receipt_service = PurchaseReceiptPdfService.new(@purchase_invoice)
    pdf_content = receipt_service.generate_and_upload_pdf
    
    # PDFを添付
    attachments["領収書_購入ID#{@purchase.id}.pdf"] = {
      mime_type: 'application/pdf',
      content: pdf_content
    }
  end
end