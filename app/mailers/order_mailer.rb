class OrderMailer < ApplicationMailer
  default from: ENV['ADMIN_EMAIL'] || 'noreply@example.com'

  def bank_transfer_instructions(purchase, purchase_invoice = nil, pdf_info = {}, pdf_content = nil)
    @purchase = purchase
    @user = purchase.user
    @total_amount = purchase.total_price
    @purchase_items = purchase.purchase_items.includes(:product)
    @purchase_invoice = purchase_invoice
    
    # PDF表示用の追加情報を設定
    @company_info = pdf_info[:company_info] || {}
    @bank_info = pdf_info[:bank_info] || {}
    
    # 送付先メールアドレスを設定
    @recipient_email = pdf_info[:recipient_email] || @user.email
    
    Rails.logger.info "Preparing bank transfer email for purchase #{@purchase.id}"
    Rails.logger.info "User email: #{@user.email}"
    Rails.logger.info "Purchase invoice present: #{@purchase_invoice.present?}"
    Rails.logger.info "PDF content provided: #{pdf_content.present?}"
    
    # 購入請求書PDFを添付
    if @purchase_invoice && pdf_content
      begin
        Rails.logger.info "Attaching PDF invoice for invoice #{@purchase_invoice.invoice_number}"
        
        # PDFファイルとして添付
        attachments["請求書_#{@purchase_invoice.invoice_number}.pdf"] = {
          mime_type: 'application/pdf',
          content: pdf_content
        }
        
        Rails.logger.info "PDF invoice attachment added successfully"
        
      rescue => e
        Rails.logger.error "Failed to attach PDF invoice: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    else
      Rails.logger.warn "No purchase_invoice or pdf_content provided for email attachment"
    end
    
    Rails.logger.info "Sending bank transfer email..."
    
    mail(
      to: @recipient_email,
      subject: "【Asia Business Trust】銀行振込のご案内・請求書 - 注文番号: ##{@purchase.id}"
    )
  end

  def payment_confirmed(purchase)
    @purchase = purchase
    @user = purchase.user
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
    
    # 会社情報を変数として定義（インスタンス変数があれば使用、なければデフォルト値）
    company_name = @company_info[:name] || "株式会社アジアビジネストラスト"
    company_department = @company_info[:department] || "アジアビジネストラスト事業部"
    company_address = @company_info[:address] || "〒104-0061 東京都中央区銀座4丁目6-1"
    company_building = @company_info[:building] || "銀座医科ビル3階"
    company_tel = @company_info[:tel] || "TEL:03-5904-8148"
    company_email = @company_info[:email] || "Email: abt1@asia-b-t.com"
    company_footer = @company_info[:footer] || "アジアビジネストラスト 事務局"
    
    # 銀行情報を変数として定義
    bank_name = @bank_info[:name] || "楽天銀行"
    bank_branch = @bank_info[:branch] || "第二営業支店"
    bank_branch_code = @bank_info[:branch_code] || "252"
    bank_account_type = @bank_info[:account_type] || "普通預金"
    bank_account_number = @bank_info[:account_number] || "7747552"
    bank_account_name = @bank_info[:account_name] || company_name
    
    # 税計算（内税）- 渡された値があれば使用、なければ計算
    total_with_tax = @total_with_tax || purchase_invoice.total_amount
    tax_rate = ENV.fetch('TAX_RATE', '0.1').to_f
    subtotal = @subtotal || (total_with_tax / (1 + tax_rate)).to_i
    tax = @tax || (total_with_tax - subtotal)
    
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
    
    # HTMLを生成（本物の請求書レイアウトに合わせて）
    <<~HTML_CONTENT
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body {
            font-family: 'MS Gothic', 'Hiragino Sans', sans-serif;
            font-size: 12px;
            line-height: 1.4;
            margin: 0;
            padding: 40px;
            color: #000;
          }
          
          .header {
            text-align: center;
            margin-bottom: 40px;
          }
          
          .header h1 {
            font-size: 24px;
            font-weight: bold;
            margin: 0;
            letter-spacing: 3px;
          }
          
          .top-section {
            display: flex;
            justify-content: space-between;
            margin-bottom: 30px;
            align-items: flex-start;
          }
          
          .customer-info {
            flex: 1;
          }
          
          .customer-name {
            font-size: 16px;
            font-weight: bold;
            margin-bottom: 20px;
          }
          
          .right-section {
            text-align: right;
            flex: 1;
          }
          
          .invoice-details {
            margin-bottom: 20px;
          }
          
          .invoice-details table {
            margin-left: auto;
            border-collapse: collapse;
            font-size: 12px;
          }
          
          .invoice-details td {
            padding: 3px 15px;
            border: none;
            text-align: left;
          }
          
          .invoice-details td:first-child {
            font-weight: bold;
            padding-right: 20px;
          }
          
          .company-info {
            font-size: 11px;
            line-height: 1.4;
            margin-top: 20px;
          }
          
          .company-name {
            font-size: 12px;
            font-weight: bold;
            margin-bottom: 3px;
          }
          
          .subject {
            margin: 20px 0;
            font-size: 14px;
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
            font-size: 12px;
          }
          
          .summary-table th {
            background-color: #f8f8f8;
            font-weight: bold;
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
            font-size: 12px;
          }
          
          .payment-info th {
            background-color: #f8f8f8;
            text-align: center;
            width: 120px;
            font-weight: bold;
          }
          
          .payment-info .bank-info {
            line-height: 1.3;
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
            font-size: 12px;
          }
          
          .items-table th {
            background-color: #f8f8f8;
            font-weight: bold;
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
            margin-top: 10px;
          }
          
          .tax-summary td {
            border: 1px solid #000;
            padding: 6px;
            text-align: right;
            font-size: 12px;
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
            font-size: 12px;
          }
          
          .notes th {
            background-color: #f8f8f8;
            width: 60px;
            font-weight: bold;
          }
          
          .page-number {
            text-align: center;
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

        <!-- 上部セクション -->
        <div class="top-section">
          <div class="customer-info">
            <div class="customer-name">#{purchase_invoice.user.name} 様</div>
          </div>
          
          <div class="right-section">
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
            
            <div class="company-info">
              <div class="company-name">#{company_name}</div>
              #{company_department}<br>
              #{company_address}<br>
              #{company_building}<br>
              #{company_tel}<br>
              #{company_email}<br>
              #{company_footer}
            </div>
          </div>
        </div>

        <!-- 件名 -->
        <div class="subject">
          <span class="subject-label"><strong>件名</strong></span>
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
            <td class="amount">#{format_price(total_with_tax)}円</td>
          </tr>
        </table>

        <!-- 支払い情報 -->
        <table class="payment-info">
          <tr>
            <th>入金期日</th>
            <th>振込先</th>
          </tr>
          <tr>
            <td><strong>#{purchase_invoice.due_date.strftime('%Y-%m-%d')}</strong></td>
            <td class="bank-info">
              #{bank_name}<br>
              支店名：#{bank_branch}<br>
              支店番号：#{bank_branch_code}<br>
              口座種別：#{bank_account_type}<br>
              口座番号：#{bank_account_number}<br>
              口座名義：#{bank_account_name}
            </td>
          </tr>
        </table>

        <!-- 商品明細 -->
        <table class="items-table">
          <thead>
            <tr>
              <th class="item-name">摘要</th>
              <th class="quantity">数量</th>
              <th class="price">単価</th>
              <th class="price">明細金額</th>
            </tr>
          </thead>
          <tbody>
            #{items_rows}
            #{empty_rows}
          </tbody>
        </table>

        <!-- 税計算 -->
        <table class="tax-summary">
          <tr>
            <td><strong>内税 #{(tax_rate * 100).to_i}%対象(税抜)</strong></td>
            <td><strong>#{format_price(subtotal)}円</strong></td>
          </tr>
          <tr>
            <td><strong>#{(tax_rate * 100).to_i}%消費税</strong></td>
            <td><strong>#{format_price(tax)}円</strong></td>
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
    
    # 会社情報を変数として定義（インスタンス変数があれば使用、なければデフォルト値）
    company_name = @company_info[:name] || "株式会社アジアビジネストラスト"
    company_department = @company_info[:department] || "アジアビジネストラスト事業部"
    company_address = @company_info[:address] || "〒104-0061 東京都中央区銀座4丁目6-1"
    company_building = @company_info[:building] || "銀座医科ビル3階"
    company_tel = @company_info[:tel] || "TEL:03-5904-8148"
    company_email = @company_info[:email] || "Email: abt1@asia-b-t.com"
    company_footer = @company_info[:footer] || "アジアビジネストラスト 事務局"
    
    # 銀行情報を変数として定義
    bank_name = @bank_info[:name] || "楽天銀行"
    bank_branch = @bank_info[:branch] || "第二営業支店"
    bank_branch_code = @bank_info[:branch_code] || "252"
    bank_account_type = @bank_info[:account_type] || "普通預金"
    bank_account_number = @bank_info[:account_number] || "7747552"
    bank_account_name = @bank_info[:account_name] || company_name
    
    # 税計算（内税）- 渡された値があれば使用、なければ計算
    total_with_tax = @total_with_tax || purchase_invoice.total_amount
    tax_rate = ENV.fetch('TAX_RATE', '0.1').to_f
    subtotal = @subtotal || (total_with_tax / (1 + tax_rate)).to_i
    tax = @tax || (total_with_tax - subtotal)
    
    # 商品明細
    items_text = purchase_invoice.purchase_items.map do |item|
      "  #{item.product.name.ljust(30)} #{item.quantity.to_s.rjust(3)}個  #{format_price(item.unit_price).rjust(8)}円  #{format_price(item.total_price).rjust(10)}円"
    end.join("\n")
    
    # 請求書テキスト
    <<~INVOICE_TEXT


                                    請求書


      #{purchase_invoice.user.name} 様                                請求日         #{purchase_invoice.invoice_date.strftime('%Y-%m-%d')}
                                                              請求書番号     #{purchase_invoice.invoice_number}
                                                              登録番号       T4210001009156


                                                              #{company_name}
                                                              #{company_department}
                                                              #{company_address}
                                                              #{company_building}
                                                              #{company_tel}
                                                              #{company_email}
                                                              #{company_footer}

      件名      幹細胞商品代

      ┌─────────────┬────────────┬──────────────┐
      │     小計     │   消費税   │   請求金額   │
      ├─────────────┼────────────┼──────────────┤
      │ #{format_price(subtotal).rjust(11)}円 │ #{format_price(tax).rjust(8)}円 │ #{format_price(total_with_tax).rjust(10)}円 │
      └─────────────┴────────────┴──────────────┘

      ┌─────────────┬──────────────────────────────────────────────────────┐
      │   入金期日   │                    振込先                            │
      ├─────────────┼──────────────────────────────────────────────────────┤
      │             │ #{bank_name}                                             │
      │             │ 支店名：#{bank_branch}                                 │
      │ #{purchase_invoice.due_date.strftime('%Y-%m-%d').ljust(11)} │ 支店番号：#{bank_branch_code}                                        │
      │             │ 口座種別：#{bank_account_type}                                   │
      │             │ 口座番号：#{bank_account_number}                                    │
      │             │ 口座名義：#{bank_account_name}             │
      └─────────────┴──────────────────────────────────────────────────────┘

      ┌──────────────────────────────────┬────────┬──────────┬──────────────┐
      │               摘要               │  数量  │   単価   │   明細金額   │
      ├──────────────────────────────────┼────────┼──────────┼──────────────┤
      #{items_text}
      ├──────────────────────────────────┴────────┴──────────┼──────────────┤
      │                          内税  #{(tax_rate * 100).to_i}%対象(税抜)        │ #{format_price(subtotal).rjust(10)}円 │
      │                               #{(tax_rate * 100).to_i}%消費税             │ #{format_price(tax).rjust(10)}円 │
      └─────────────────────────────────────────────────────┴──────────────┘

      ┌─────────────────────────────────────────────────────────────────────────┐
      │ 備考                                                                    │
      │ 振込手数料はお客様負担にて、期日までのお振込をお願いいたします。        │
      └─────────────────────────────────────────────────────────────────────────┘

                                                                          1 / 1
    INVOICE_TEXT
  end
end