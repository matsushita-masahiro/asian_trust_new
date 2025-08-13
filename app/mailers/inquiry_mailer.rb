# app/mailers/inquiry_mailer.rb
class InquiryMailer < ApplicationMailer
  default from: ENV['ADMIN_EMAIL']

  def notify_admin(inquiry)
    @inquiry = inquiry
    mail(to: ENV['ADMIN_EMAIL'], subject: "【#{ENV['COMPANY_NAME']}】新しいお問い合わせを受信しました")

  end

  def thanks_to_user(inquiry)
    @inquiry = inquiry
    mail(to: @inquiry.email, subject: "【#{ENV['COMPANY_NAME']}】お問い合わせありがとうございます")
  end
end
