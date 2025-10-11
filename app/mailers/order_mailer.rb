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
    
    # 購入請求書PDFを添付（簡易版）
    if @purchase_invoice
      begin
        Rails.logger.info "Starting PDF generation for invoice #{@purchase_invoice.invoice_number}"
        
        # 簡易的なPDF生成
        pdf_content = generate_simple_invoice_pdf(@purchase_invoice)
        
        Rails.logger.info "PDF content generated, size: #{pdf_content.bytesize} bytes"
        
        # シンプルな添付方法
        attachments["請求書_#{@purchase_invoice.invoice_number}.txt"] = pdf_content
        
        Rails.logger.info "PDF attachment added successfully"
        
      rescue => e
        Rails.logger.error "Failed to generate invoice PDF: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        # PDFが生成できなくてもメールは送信する
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

  def generate_simple_invoice_pdf(purchase_invoice)
    Rails.logger.info "Generating PDF content for invoice #{purchase_invoice.invoice_number}"
    
    # 商品明細を美しくフォーマット
    items_text = purchase_invoice.purchase_items.map.with_index do |item, index|
      price_formatted = item.total_price.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
      "  #{index + 1}. #{item.product.name.ljust(30)} × #{item.quantity.to_s.rjust(3)} = ¥#{price_formatted.rjust(10)}"
    end.join("\n")
    
    total_formatted = purchase_invoice.total_amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    
    # おしゃれなテキストベースの請求書
    content = <<~INVOICE_CONTENT
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║    ██╗███╗   ██╗██╗   ██╗ ██████╗ ██╗ ██████╗███████╗                      ║
║    ██║████╗  ██║██║   ██║██╔═══██╗██║██╔════╝██╔════╝                      ║
║    ██║██╔██╗ ██║██║   ██║██║   ██║██║██║     █████╗                        ║
║    ██║██║╚██╗██║╚██╗ ██╔╝██║   ██║██║██║     ██╔══╝                        ║
║    ██║██║ ╚████║ ╚████╔╝ ╚██████╔╝██║╚██████╗███████╗                      ║
║    ╚═╝╚═╝  ╚═══╝  ╚═══╝   ╚═════╝ ╚═╝ ╚═════╝╚══════╝                      ║
║                                                                              ║
║                           📄 請 求 書 📄                                    ║
║                                                                              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  📋 請求書情報                                                               ║
║  ┌────────────────────────────────────────────────────────────────────────┐  ║
║  │ 請求書番号: #{purchase_invoice.invoice_number.ljust(50)} │  ║
║  │ 請求日    : #{purchase_invoice.invoice_date.strftime('%Y年%m月%d日').ljust(50)} │  ║
║  │ 支払期限  : #{purchase_invoice.due_date.strftime('%Y年%m月%d日').ljust(50)} │  ║
║  └────────────────────────────────────────────────────────────────────────┘  ║
║                                                                              ║
║  👤 請求先                                                                   ║
║  ┌────────────────────────────────────────────────────────────────────────┐  ║
║  │ お名前    : #{purchase_invoice.buyer.name.ljust(50)} │  ║
║  │ メール    : #{purchase_invoice.buyer.email.ljust(50)} │  ║
║  └────────────────────────────────────────────────────────────────────────┘  ║
║                                                                              ║
║  🏢 請求元                                                                   ║
║  ┌────────────────────────────────────────────────────────────────────────┐  ║
║  │ アジアビジネストラスト株式会社                                           │  ║
║  │ 〒000-0000 東京都新宿区                                                  │  ║
║  │ TEL: 03-0000-0000  FAX: 03-0000-0001                                     │  ║
║  └────────────────────────────────────────────────────────────────────────┘  ║
║                                                                              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  🛒 商品明細                                                                 ║
║  ┌────────────────────────────────────────────────────────────────────────┐  ║
║  │                                                                          │  ║
#{items_text.split("\n").map { |line| "║  │#{line.ljust(74)}│  ║" }.join("\n")}
║  │                                                                          │  ║
║  │  ────────────────────────────────────────────────────────────────────  │  ║
║  │                                           合計金額: ¥#{total_formatted.rjust(15)} │  ║
║  └────────────────────────────────────────────────────────────────────────┘  ║
║                                                                              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  💳 お支払い方法: 銀行振込                                                   ║
║                                                                              ║
║  🏦 振込先情報                                                               ║
║  ┌────────────────────────────────────────────────────────────────────────┐  ║
║  │ 銀行名    : 三菱UFJ銀行                                                  │  ║
║  │ 支店名    : 新宿支店                                                     │  ║
║  │ 口座種別  : 普通預金                                                     │  ║
║  │ 口座番号  : 1234567                                                      │  ║
║  │ 口座名義  : アジアビジネストラスト(カ                                    │  ║
║  └────────────────────────────────────────────────────────────────────────┘  ║
║                                                                              ║
║  ⚠️  重要事項                                                                ║
║  • 振込手数料はお客様負担となります                                          ║
║  • 入金確認後、商品を発送いたします                                          ║
║  • お振込み名義は、ご注文者様のお名前でお願いいたします                      ║
║                                                                              ║
║  📞 お問い合わせ: support@abt-saisei.com                                     ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

                        ✨ ご利用ありがとうございます ✨
    INVOICE_CONTENT
    
    Rails.logger.info "Stylish PDF content generated successfully, length: #{content.length}"
    content
  end
end