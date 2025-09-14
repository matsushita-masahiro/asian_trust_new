class OrderMailer < ApplicationMailer
  default from: ENV['ADMIN_EMAIL'] || 'noreply@example.com'

  def bank_transfer_instructions(purchase)
    @purchase = purchase
    @user = purchase.buyer
    @total_amount = purchase.total_price
    @purchase_items = purchase.purchase_items.includes(:product)
    
    mail(
      to: @user.email,
      subject: "【Asian Business Trust】銀行振込のご案内 - 注文番号: ##{@purchase.id}"
    )
  end
end