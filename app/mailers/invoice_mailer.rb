class InvoiceMailer < ApplicationMailer
  def send_invoice(invoice)
    @invoice = invoice
    @user = invoice.user
    @invoice_recipient = invoice.invoice_recipient
    
    # PDF生成
    pdf = WickedPdf.new.pdf_from_string(
      render_to_string(
        template: 'invoices/pdf',
        layout: 'pdf',
        locals: { invoice: @invoice, user: @user }
      ),
      page_size: 'A4',
      margin: { top: 20, bottom: 20, left: 20, right: 20 }
    )
    
    # PDFを添付
    attachments["請求書_INV-#{@invoice.id.to_s.rjust(6, '0')}.pdf"] = pdf
    
    mail(
      from: ENV['ADMIN_EMAIL'] || 'admin@example.com',
      to: @invoice_recipient.email,
      subject: "【請求書送付】INV-#{@invoice.id.to_s.rjust(6, '0')} - #{@user.name || @user.email}様より"
    )
  end
end
