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
    
    # 購入請求書を添付（シンプルなテキスト版に戻す）
    if @purchase_invoice
      begin
        Rails.logger.info "Starting invoice generation for invoice #{@purchase_invoice.invoice_number}"
        
        # シンプルなテキスト版請求書を生成
        invoice_content = generate_invoice_text(@purchase_invoice)
        
        Rails.logger.info "Invoice content generated, size: #{invoice_content.bytesize} bytes"
        
        # テキストファイルとして添付
        attachments["請求書_#{@purchase_invoice.invoice_number}.txt"] = {
          mime_type: 'text/plain; charset=UTF-8',
          content: invoice_content
        }
        
        Rails.logger.info "Invoice attachment added successfully"
        
      rescue => e
        Rails.logger.error "Failed to generate invoice: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        # 請求書が生成できなくてもメールは送信する
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

  def generate_invoice_text(purchase_invoice)
    # 数値フォーマット用のヘルパー
    def format_price(amount)
      amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    end
    
    # 税計算
    subtotal = (purchase_invoice.total_amount / 1.1).to_i
    tax = (purchase_invoice.total_amount * 0.1 / 1.1).to_i
    
    # 商品明細
    items_text = purchase_invoice.purchase_items.map do |item|
      "  #{item.product.name.ljust(30)} #{item.quantity.to_s.rjust(3)}個  #{format_price(item.unit_price).rjust(8)}円  #{format_price(item.total_price).rjust(10)}円"
    end.join("\n")
    
    # 請求書テキスト
    <<~INVOICE_TEXT


                                    請求書


      #{purchase_invoice.buyer.name} 様                                請求日         #{purchase_invoice.invoice_date.strftime('%Y-%m-%d')}
                                                              請求書番号     #{purchase_invoice.invoice_number}
                                                              登録番号       T4210001009156


                                                              株式会社アジアビジネストラスト
                                                              アジアビジネストラスト事業部
                                                              〒104-0061 東京都中央区銀座4丁目6-1
                                                              銀座医科ビル3階
                                                              TEL:03-5904-8148
                                                              Email: abt1@asia-b-t.com
                                                              アジアビジネストラスト 事務局

      件名      幹細胞商品代

      ┌─────────────┬────────────┬──────────────┐
      │     小計     │   消費税   │   請求金額   │
      ├─────────────┼────────────┼──────────────┤
      │ #{format_price(subtotal).rjust(11)}円 │ #{format_price(tax).rjust(8)}円 │ #{format_price(purchase_invoice.total_amount).rjust(10)}円 │
      └─────────────┴────────────┴──────────────┘

      ┌─────────────┬──────────────────────────────────────────────────────┐
      │   入金期日   │                    振込先                            │
      ├─────────────┼──────────────────────────────────────────────────────┤
      │             │ 楽天銀行                                             │
      │             │ 支店名：第二営業支店                                 │
      │ #{purchase_invoice.due_date.strftime('%Y-%m-%d').ljust(11)} │ 支店番号：252                                        │
      │             │ 口座種別：普通預金                                   │
      │             │ 口座番号：7747552                                    │
      │             │ 口座名義：株式会社アジアビジネストラスト             │
      └─────────────┴──────────────────────────────────────────────────────┘

      ┌──────────────────────────────────┬────────┬──────────┬──────────────┐
      │               摘要               │  数量  │   単価   │   明細金額   │
      ├──────────────────────────────────┼────────┼──────────┼──────────────┤
      #{items_text}
      ├──────────────────────────────────┴────────┴──────────┼──────────────┤
      │                          内税  10%対象(税抜)        │ #{format_price(subtotal).rjust(10)}円 │
      │                               10%消費税             │ #{format_price(tax).rjust(10)}円 │
      └─────────────────────────────────────────────────────┴──────────────┘

      ┌─────────────────────────────────────────────────────────────────────────┐
      │ 備考                                                                    │
      │ 振込手数料はお客様負担にて、期日までのお振込をお願いいたします。        │
      └─────────────────────────────────────────────────────────────────────────┘

                                                                          1 / 1
    INVOICE_TEXT
  end
end