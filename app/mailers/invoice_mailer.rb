class InvoiceMailer < ApplicationMailer
  def send_invoice(invoice)
    @invoice = invoice
    @user = invoice.user
    @invoice_recipient = invoice.invoice_recipient
    
    # 明細データを取得（請求書の発行日から月を特定）
    invoice_month = @invoice.invoice_date
    if invoice_month
      month_start = invoice_month.beginning_of_month
      month_end = invoice_month.end_of_month
      @bonus_details = get_bonus_details_for_user(@user, month_start, month_end)
    else
      @bonus_details = []
    end
    
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

  private

  def get_bonus_details_for_user(user, start_date, end_date)
    details = []
    
    # 自分の販売に対するボーナス
    self_purchases = user.purchases.where(purchased_at: start_date..end_date)
    self_purchases.each do |purchase|
      product = purchase.product
      base_price = product.base_price
      my_price = product.product_prices.find_by(level_id: user.level_id)&.price || 0
      bonus = (base_price - my_price) * purchase.quantity
      
      if bonus > 0
        details << {
          type: '自己販売',
          user_name: user.name || user.email,
          product_name: product.name,
          quantity: purchase.quantity,
          unit_bonus: bonus / purchase.quantity,
          total_bonus: bonus,
          purchased_at: purchase.purchased_at
        }
      end
    end
    
    # 子孫の販売に対するボーナス
    descendant_purchases = Purchase.includes(:product, :user)
                                   .where(user_id: user.descendant_ids)
                                   .where(purchased_at: start_date..end_date)
    
    descendant_purchases.each do |purchase|
      bonus = user.bonus_for_purchase(purchase)
      
      if bonus > 0
        details << {
          type: '下位販売',
          user_name: purchase.user.name || purchase.user.email,
          product_name: purchase.product.name,
          quantity: purchase.quantity,
          unit_bonus: bonus / purchase.quantity,
          total_bonus: bonus,
          purchased_at: purchase.purchased_at
        }
      end
    end
    
    # 日付順でソート
    details.sort_by { |d| d[:purchased_at] }
  end
end
