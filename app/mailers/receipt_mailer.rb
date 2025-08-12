# app/mailers/receipt_mailer.rb
class ReceiptMailer < ApplicationMailer
  def send_receipt(invoice)
    @invoice = invoice
    @user    = invoice.user
    @invoice_recipients = InvoiceRecipient.first # 既存テンプレで参照しているなら維持
    @invoice_base = @user.invoice_base

    # 送信先（請求先メール > ユーザーのメール の順でフォールバック）
    recipient_email = @invoice_base&.email.presence || @user.email

    Rails.logger.info "💌 Sending receipt to: #{recipient_email.inspect}"
    Rails.logger.info "From: #{(ENV['ADMIN_EMAIL'] || 'info@abt-saisei.com').inspect}"

    # ボーナス明細（請求対象月に合わせる）
    if @invoice.target_month.present?
      month_start = Date.strptime(@invoice.target_month, "%Y-%m").beginning_of_month
      month_end   = Date.strptime(@invoice.target_month, "%Y-%m").end_of_month
      @bonus_details = get_bonus_details_for_user(@user, month_start, month_end)
    else
      @bonus_details = []
    end

    # 念のためクリア
    attachments.clear

    # PDF HTML をレンダリング（レイアウト/テンプレはプロジェクトに合わせて）
    pdf_html = render_to_string(
      template: 'invoices/receipt_pdf',
      layout:   'pdf',
      locals: {
        invoice:            @invoice,
        user:               @user,
        invoice_recipients: @invoice_recipients,
        invoice_base:       @invoice_base,
        bonus_details:      @bonus_details
      }
    )

    # PDF 生成
    pdf = WickedPdf.new.pdf_from_string(
      pdf_html,
      page_size: 'A4',
      margin: { top: 15, bottom: 15, left: 15, right: 15 },
      encoding: 'UTF-8',
      disable_smart_shrinking: false,
      zoom: 0.8
    )

    # 添付ファイル
    attachments["領収書_REC-#{@invoice.id.to_s.rjust(6, '0')}.pdf"] = {
      mime_type: 'application/pdf',
      content: pdf
    }

    # 送信
    mail(
      from:    ENV['ADMIN_EMAIL'] || 'info@abt-saisei.com',
      to:      recipient_email,
      subject: "【領収書発行】領収書番号: REC-#{@invoice.id.to_s.rjust(6, '0')}"
    )
  rescue => e
    Rails.logger.error("❌ ReceiptMailer#send_receipt failed: #{e.class} #{e.message}")
    raise
  end

  private

  # 1購入複数明細対応：自己/下位ともに purchase_items ベースで集計
  def get_bonus_details_for_user(user, start_date, end_date)
    details = []

    # 自己販売（明細ベース）
    self_purchases = user.purchases
                         .where(purchased_at: start_date..end_date)
                         .includes(purchase_items: :product)

    self_purchases.each do |purchase|
      purchase.purchase_items.each do |item|
        product     = item.product
        base_price  = product.base_price
        my_price    = product.product_prices.find_by(level_id: user.level_id)&.price || 0
        unit_bonus  = base_price - my_price
        total_bonus = unit_bonus * item.quantity
        next if total_bonus <= 0

        details << {
          type:         '自己販売',
          user_name:    user.name || user.email,
          product_name: product.name,
          quantity:     item.quantity,
          unit_price:   base_price,               # 表示用：基準単価
          unit_bonus:   unit_bonus,
          total_bonus:  total_bonus,
          purchased_at: purchase.purchased_at
        }
      end
    end

    # 下位販売（明細ベース）
    descendant_purchases = Purchase
      .where(user_id: user.descendant_ids, purchased_at: start_date..end_date)
      .includes(:user, purchase_items: :product)

    descendant_purchases.each do |purchase|
      purchase.purchase_items.each do |item|
        bonus =
          if user.respond_to?(:bonus_for_purchase_item)
            user.bonus_for_purchase_item(item).to_i
          elsif user.respond_to?(:bonus_for_purchase)
            # 旧APIしかない場合は購入合計ボーナスを金額按分（保険）
            total_for_purchase = user.bonus_for_purchase(purchase).to_i
            purchase_total = purchase.purchase_items.sum { |it| it.quantity * it.unit_price }
            item_total     = item.quantity * item.unit_price
            purchase_total.positive? ? (total_for_purchase * item_total / purchase_total) : 0
          else
            0
          end

        next if bonus <= 0

        details << {
          type:         '下位販売',
          user_name:    purchase.user.name || purchase.user.email,
          product_name: item.product.name,
          quantity:     item.quantity,
          unit_price:   item.product.base_price,  # 表示用
          unit_bonus:   (bonus.to_f / item.quantity).round,
          total_bonus:  bonus,
          purchased_at: purchase.purchased_at
        }
      end
    end

    # 購入日順
    details.sort_by { |d| d[:purchased_at] }
  end
end
