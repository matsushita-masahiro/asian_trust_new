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
        Rails.logger.info "Starting PDF invoice generation for invoice #{@purchase_invoice.invoice_number}"
        
        # HTMLを直接生成
        html_content = generate_invoice_html(@purchase_invoice)
        Rails.logger.info "HTML content generated, size: #{html_content.bytesize} bytes"
        
        # PDFを生成
        pdf_content = WickedPdf.new.pdf_from_string(
          html_content,
          page_size: 'A4',
          margin: {
            top: 20,
            bottom: 20,
            left: 20,
            right: 20
          },
          encoding: 'UTF-8',
          print_media_type: true
        )
        
        Rails.logger.info "PDF content generated, size: #{pdf_content.bytesize} bytes"
        
        # PDFファイルとして添付
        attachments["請求書_#{@purchase_invoice.invoice_number}.pdf"] = {
          mime_type: 'application/pdf',
          content: pdf_content
        }
        
        Rails.logger.info "PDF invoice attachment added successfully"
        
      rescue => e
        Rails.logger.error "Failed to generate PDF invoice: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        
        # PDFが生成できない場合はHTMLにフォールバック
        begin
          html_content = generate_invoice_html(@purchase_invoice)
          attachments["請求書_#{@purchase_invoice.invoice_number}.html"] = {
            mime_type: 'text/html; charset=UTF-8',
            content: html_content
          }
          Rails.logger.info "Fallback to HTML attachment successful"
        rescue => fallback_error
          Rails.logger.error "Fallback HTML generation also failed: #{fallback_error.message}"
        end
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

  def generate_invoice_html(purchase_invoice)
    # 数値フォーマット用のヘルパー
    def format_price(amount)
      amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    end
    
    # 税計算
    subtotal = (purchase_invoice.total_amount / 1.1).to_i
    tax = (purchase_invoice.total_amount * 0.1 / 1.1).to_i
    
    # 商品明細行を生成
    items_rows = purchase_invoice.purchase_items.map do |item|
      <<~ITEM_ROW
        <tr>
          <td class="item-name">#{item.product.name}</td>
          <td class="quantity">#{item.quantity}</td>
          <td class="price">#{format_price(item.unit_price)}</td>
          <td class="price">#{format_price(item.total_price)}</td>
        </tr>
      ITEM_ROW
    end.join
    
    # 空行を追加（最大10行まで）
    empty_rows_count = [10 - purchase_invoice.purchase_items.count, 0].max
    empty_rows = (1..empty_rows_count).map do
      <<~EMPTY_ROW
        <tr>
          <td class="item-name">&nbsp;</td>
          <td class="quantity">&nbsp;</td>
          <td class="price">&nbsp;</td>
          <td class="price">&nbsp;</td>
        </tr>
      EMPTY_ROW
    end.join
    
    # HTMLを生成
    <<~HTML_CONTENT
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body {
            font-family: 'Hiragino Sans', 'MS Gothic', sans-serif;
            font-size: 12px;
            line-height: 1.4;
            margin: 0;
            padding: 20px;
            color: #000;
          }
          
          .header {
            text-align: center;
            margin-bottom: 30px;
          }
          
          .header h1 {
            font-size: 24px;
            font-weight: bold;
            margin: 0;
          }
          
          .invoice-info {
            display: flex;
            justify-content: space-between;
            margin-bottom: 30px;
          }
          
          .customer-info {
            flex: 1;
          }
          
          .customer-name {
            font-size: 16px;
            font-weight: bold;
            margin-bottom: 20px;
          }
          
          .invoice-details {
            text-align: right;
            flex: 1;
          }
          
          .invoice-details table {
            margin-left: auto;
            border-collapse: collapse;
          }
          
          .invoice-details td {
            padding: 3px 10px;
            border: none;
          }
          
          .company-info {
            position: relative;
            text-align: right;
            margin-bottom: 20px;
          }
          
          .company-logo {
            position: absolute;
            right: 0;
            top: 0;
            width: 80px;
            height: 80px;
          }
          
          .company-details {
            margin-right: 90px;
            font-size: 11px;
            line-height: 1.3;
          }
          
          .subject {
            margin: 20px 0;
          }
          
          .subject-label {
            font-weight: bold;
            display: inline-block;
            width: 60px;
          }
          
          .summary-table {
            width: 400px;
            border-collapse: collapse;
            margin: 20px 0;
          }
          
          .summary-table th,
          .summary-table td {
            border: 1px solid #000;
            padding: 8px;
            text-align: center;
          }
          
          .summary-table .amount {
            font-size: 18px;
            font-weight: bold;
          }
          
          .payment-info {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
          }
          
          .payment-info th,
          .payment-info td {
            border: 1px solid #000;
            padding: 8px;
            vertical-align: top;
          }
          
          .payment-info th {
            background-color: #f0f0f0;
            text-align: center;
            width: 120px;
          }
          
          .items-table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
          }
          
          .items-table th,
          .items-table td {
            border: 1px solid #000;
            padding: 6px;
            text-align: center;
          }
          
          .items-table th {
            background-color: #f0f0f0;
          }
          
          .items-table .item-name {
            text-align: left;
            width: 300px;
          }
          
          .items-table .quantity {
            width: 80px;
          }
          
          .items-table .price {
            width: 100px;
            text-align: right;
          }
          
          .tax-summary {
            width: 300px;
            margin-left: auto;
            border-collapse: collapse;
          }
          
          .tax-summary td {
            border: 1px solid #000;
            padding: 6px;
            text-align: right;
          }
          
          .notes {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
          }
          
          .notes th,
          .notes td {
            border: 1px solid #000;
            padding: 8px;
            vertical-align: top;
          }
          
          .notes th {
            background-color: #f0f0f0;
            width: 60px;
          }
          
          .page-number {
            text-align: right;
            margin-top: 30px;
            font-size: 12px;
          }
        </style>
      </head>
      <body>
        <!-- ヘッダー -->
        <div class="header">
          <h1>請求書</h1>
        </div>

        <!-- 請求書情報 -->
        <div class="invoice-info">
          <div class="customer-info">
            <div class="customer-name">#{purchase_invoice.buyer.name} 様</div>
          </div>
          
          <div class="invoice-details">
            <table>
              <tr>
                <td>請求日</td>
                <td>#{purchase_invoice.invoice_date.strftime('%Y-%m-%d')}</td>
              </tr>
              <tr>
                <td>請求書番号</td>
                <td>#{purchase_invoice.invoice_number}</td>
              </tr>
              <tr>
                <td>登録番号</td>
                <td>T4210001009156</td>
              </tr>
            </table>
          </div>
        </div>

        <!-- 会社情報とロゴ -->
        <div class="company-info">
          <div class="company-details">
            株式会社アジアビジネストラスト<br>
            アジアビジネストラスト事業部<br>
            〒104-0061 東京都中央区銀座4丁目6-1<br>
            銀座医科ビル3階<br>
            TEL:03-5904-8148<br>
            Email: abt1@asia-b-t.com<br>
            アジアビジネストラスト 事務局
          </div>
        </div>

        <!-- 件名 -->
        <div class="subject">
          <span class="subject-label">件名</span>
          <span>幹細胞商品代</span>
        </div>

        <!-- 金額サマリー -->
        <table class="summary-table">
          <tr>
            <th>小計</th>
            <th>消費税</th>
            <th>請求金額</th>
          </tr>
          <tr>
            <td>#{format_price(subtotal)}円</td>
            <td>#{format_price(tax)}円</td>
            <td class="amount">#{format_price(purchase_invoice.total_amount)}円</td>
          </tr>
        </table>

        <!-- 支払い情報 -->
        <table class="payment-info">
          <tr>
            <th>入金期日</th>
            <th>振込先</th>
          </tr>
          <tr>
            <td>#{purchase_invoice.due_date.strftime('%Y-%m-%d')}</td>
            <td>
              楽天銀行<br>
              支店名：第二営業支店<br>
              支店番号：252<br>
              口座種別：普通預金<br>
              口座番号：7747552<br>
              口座名義：株式会社アジアビジネストラスト
            </td>
          </tr>
        </table>

        <!-- 商品明細 -->
        <table class="items-table">
          <tr>
            <th class="item-name">摘要</th>
            <th class="quantity">数量</th>
            <th class="price">単価</th>
            <th class="price">明細金額</th>
          </tr>
          #{items_rows}
          #{empty_rows}
        </table>

        <!-- 税計算 -->
        <table class="tax-summary">
          <tr>
            <td>内税 10%対象(税抜)</td>
            <td>#{format_price(subtotal)}円</td>
          </tr>
          <tr>
            <td>10%消費税</td>
            <td>#{format_price(tax)}円</td>
          </tr>
        </table>

        <!-- 備考 -->
        <table class="notes">
          <tr>
            <th>備考</th>
            <td>振込手数料はお客様負担にて、期日までのお振込をお願いいたします。</td>
          </tr>
        </table>

        <!-- ページ番号 -->
        <div class="page-number">1 / 1</div>
      </body>
      </html>
    HTML_CONTENT
  end

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