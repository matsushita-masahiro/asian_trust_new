# app/mailers/inquiry_mailer.rb
class InquiryMailer < ApplicationMailer
  default from: 'info@msworks.tokyo'

  def notify_admin(inquiry)
    @inquiry = inquiry
    mail(to: 'info@msworks.tokyo', subject: '【MS Works】新しいお問い合わせを受信しました')
  end

  def thanks_to_user(inquiry)
    @inquiry = inquiry
    mail(to: @inquiry.email, subject: '【MS Works】お問い合わせありがとうございます')
  end
end
