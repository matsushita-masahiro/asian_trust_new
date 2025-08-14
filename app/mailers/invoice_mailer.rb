class InvoiceMailer < ApplicationMailer
  def send_invoice(invoice, pdf_content = nil)
    @invoice = invoice
    @user = invoice.user
    @invoice_recipient = invoice.invoice_recipient

    if @invoice.target_month.present?
      month_start = Date.strptime(@invoice.target_month, "%Y-%m").beginning_of_month
      month_end   = Date.strptime(@invoice.target_month, "%Y-%m").end_of_month
      @bonus_details = get_bonus_details_for_user(@user, month_start, month_end)
    else
      @bonus_details = []
    end

    # 外部から渡されたPDFがあればそれを使用、なければ従来通り生成
    if pdf_content
      pdf = pdf_content
    else
      pdf = WickedPdf.new.pdf_from_string(
        render_to_string(
          template: 'invoices/pdf', # or 'invoices/pdf_new'
          layout: 'pdf',
          locals: { invoice: @invoice, user: @user }
        ),
        page_size: 'A4',
        margin: { top: 20, bottom: 20, left: 20, right: 20 }
      )
    end

    attachments["請求書_INV-#{@invoice.id.to_s.rjust(6, '0')}.pdf"] = pdf

    mail(
      from: ENV['ADMIN_EMAIL'] || 'admin@example.com',
      to:   @invoice_recipient.email,
      subject: "【請求書送付】INV-#{@invoice.id.to_s.rjust(6, '0')} - #{@user.name || @user.email}様より"
    )
  end

  private

  # 1購入複数明細対応版
  def get_bonus_details_for_user(user, start_date, end_date)
    details = []

    # 自身の販売（明細単位・購入当時の価格で固定）
    user.purchases
        .where(purchased_at: start_date..end_date)
        .includes(purchase_items: :product)
        .find_each do |purchase|
      purchase.purchase_items.each do |item|
        unit_base   = item.unit_price.to_i                  # 購入当時の基準単価
        seller_unit = item.seller_price.to_i                # 購入当時の販売店単価
        # 旧データ対策（seller_price が nil/0 の場合はユーザのレベル価格→なければ unit_price）
        if seller_unit <= 0
          seller_unit = item.product.product_prices.find_by(level_id: user.level_id)&.price.to_i
          seller_unit = item.unit_price.to_i if seller_unit <= 0
        end

        unit_bonus  = unit_base - seller_unit
        total_bonus = unit_bonus * item.quantity
        next if total_bonus <= 0

        details << {
          type: '自己販売',
          user_name: user.name || user.email,
          product_name: item.product.name,
          quantity: item.quantity,
          unit_bonus: unit_bonus,
          total_bonus: total_bonus,
          purchased_at: purchase.purchased_at
        }
      end
    end

    # 下位の販売（明細単位）
    Purchase.where(user_id: user.descendant_ids, purchased_at: start_date..end_date)
            .includes(:user, purchase_items: :product)
            .find_each do |purchase|
      purchase.purchase_items.each do |item|
        bonus = user.respond_to?(:bonus_for_purchase_item) ? user.bonus_for_purchase_item(item).to_i : 0
        next if bonus <= 0

        qty = item.quantity.nonzero? || 1
        details << {
          type: '下位販売',
          user_name: purchase.user.name || purchase.user.email,
          product_name: item.product.name,
          quantity: item.quantity,
          unit_bonus: (bonus.to_f / qty).round,
          total_bonus: bonus,
          purchased_at: purchase.purchased_at
        }
      end
    end

    details.sort_by { |d| d[:purchased_at] }
  end

end
