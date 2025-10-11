class OrderMailer < ApplicationMailer
  default from: ENV['ADMIN_EMAIL'] || 'noreply@example.com'

  def bank_transfer_instructions(purchase, purchase_invoice = nil)
    @purchase = purchase
    @user = purchase.buyer
    @total_amount = purchase.total_price
    @purchase_items = purchase.purchase_items.includes(:product)
    @purchase_invoice = purchase_invoice
    
    # 購入請求書PDFを添付（簡易版）
    if @purchase_invoice
      begin
        Rails.logger.info "Starting PDF generation for invoice #{@purchase_invoice.invoice_number}"
        
        # 簡易的なPDF生成（後でPDFサービスに置き換え予定）
        pdf_content = generate_simple_invoice_pdf(@purchase_invoice)
        
        Rails.logger.info "PDF content generated, size: #{pdf_content.bytesize} bytes"
        
        # PDFとして添付（content-typeを明示的に指定）
        attachments["請求書_#{@purchase_invoice.invoice_number}.txt"] = {
          mime_type: 'text/plain',
          content: pdf_content
        }
        
        Rails.logger.info "PDF attachment added successfully"
        
      rescue => e
        Rails.logger.error "Failed to generate invoice PDF: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        # PDFが生成できなくてもメールは送信する
      end
    else
      Rails.logger.warn "No purchase_invoice provided for email attachment"
    end
    
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
    
    begin
      # 商品明細を安全に生成
      items_text = purchase_invoice.purchase_items.map do |item|
        "#{item.product.name} × #{item.quantity} = #{ActionController::Base.helpers.number_with_delimiter(item.total_price)}円"
      end.join("\n")
      
      # 簡易的なテキストベースの請求書（後で本格的なPDFライブラリに置き換え）
      content = <<~INVOICE_CONTENT
==========================================
請求書
==========================================

請求書番号: #{purchase_invoice.invoice_number}
請求日: #{purchase_invoice.invoice_date.strftime('%Y年%m月%d日')}
支払期限: #{purchase_invoice.due_date.strftime('%Y年%m月%d日')}

==========================================
請求先
==========================================
#{purchase_invoice.buyer.name}
#{purchase_invoice.buyer.email}

==========================================
請求元
==========================================
アジアビジネストラスト株式会社

==========================================
商品明細
==========================================
#{items_text}

==========================================
合計金額: #{ActionController::Base.helpers.number_with_delimiter(purchase_invoice.total_amount)}円
==========================================

お支払い方法: 銀行振込

振込先:
銀行名: 三菱UFJ銀行
支店名: 新宿支店
口座種別: 普通
口座番号: 1234567
口座名義: アジアビジネストラスト(カ

※振込手数料はお客様負担となります
※入金確認後、商品を発送いたします
      INVOICE_CONTENT
      
      Rails.logger.info "PDF content generated successfully, length: #{content.length}"
      content.encode('UTF-8')
      
    rescue => e
      Rails.logger.error "Error in generate_simple_invoice_pdf: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end
end