class ReceiptMailer < ApplicationMailer
  def send_receipt(invoice)
    @invoice = invoice
    @user = invoice.user
    @invoice_recipients = InvoiceRecipient.first
    @invoice_base = @user.invoice_base

    # 送信先メールアドレス
    recipient_email = @user.invoice_base&.email || @user.email

    # ボーナス詳細データを取得
    selected_month = @invoice.invoice_date&.strftime("%Y-%m") || Date.current.strftime("%Y-%m")
    selected_month_start = Date.strptime(selected_month, "%Y-%m").beginning_of_month
    selected_month_end = Date.strptime(selected_month, "%Y-%m").end_of_month
    @bonus_details = get_bonus_details(selected_month_start, selected_month_end)

    # 添付ファイルをクリア（重複防止）
    attachments.clear

    # PDF用HTMLをレンダリング（assignsで明示的に変数を渡す）
    pdf_html = ApplicationController.new.render_to_string(
      template: 'invoices/receipt_pdf',
      layout: false,
      assigns: {
        invoice: @invoice,
        user: @user,
        invoice_recipients: @invoice_recipients,
        invoice_base: @invoice_base,
        bonus_details: @bonus_details
      }
    )

    # PDF生成（例外を捕捉してログ出力）
    begin
      pdf = WickedPdf.new.pdf_from_string(
        pdf_html,
        page_size: 'A4',
        margin: { top: 15, bottom: 15, left: 15, right: 15 },
        encoding: 'UTF-8',
        disable_smart_shrinking: false,
        zoom: 0.8
      )
    rescue => e
      Rails.logger.error("PDF生成に失敗: #{e.message}")
      raise
    end

    # PDF添付（1通につき1ファイル）
    attachments["領収書_REC-#{@invoice.id.to_s.rjust(6, '0')}.pdf"] = {
      mime_type: 'application/pdf',
      content: pdf
    }

    # メール送信
    mail(
      from: ENV['ADMIN_EMAIL'],
      to: recipient_email,
      subject: "【領収書発行】領収書番号: REC-#{@invoice.id.to_s.rjust(6, '0')}"
    )
  end

  private

  def get_bonus_details(start_date, end_date)
    details = []

    # 自分の販売分
    self_purchases = @user.purchases.includes(:product).where(purchased_at: start_date..end_date)
    self_purchases.each do |purchase|
      product = purchase.product
      base_price = product.base_price
      my_price = product.product_prices.find_by(level_id: @user.level_id)&.price || 0
      bonus = (base_price - my_price) * purchase.quantity

      if bonus > 0
        details << {
          type: '自己販売',
          user_name: @user.name || @user.email,
          product_name: product.name,
          quantity: purchase.quantity,
          unit_price: base_price,
          unit_bonus: bonus / purchase.quantity,
          total_bonus: bonus,
          purchased_at: purchase.purchased_at
        }
      end
    end

    # 子孫の販売分
    descendant_purchases = Purchase.includes(:product, :user)
                                   .where(user_id: @user.descendant_ids)
                                   .where(purchased_at: start_date..end_date)

    descendant_purchases.each do |purchase|
      bonus = @user.bonus_for_purchase(purchase)

      if bonus > 0
        details << {
          type: '下位販売',
          user_name: purchase.user.name || purchase.user.email,
          product_name: purchase.product.name,
          quantity: purchase.quantity,
          unit_price: purchase.product.base_price,
          unit_bonus: bonus / purchase.quantity,
          total_bonus: bonus,
          purchased_at: purchase.purchased_at
        }
      end
    end

    # 日付順ソート
    details.sort_by { |d| d[:purchased_at] }
  end
end
