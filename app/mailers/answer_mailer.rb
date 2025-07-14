class AnswerMailer < ApplicationMailer
  default from: ENV['ADMIN_MAIL'] # 例: info@msworks.tokyo

  def notify_user(answer)
    @answer = answer
    @inquiry = answer.inquiry
    mail(
      to: @inquiry.email,
      subject: "【#{ENV['COMPANY_NAME']}】お問い合わせへのご回答"
    )
  end
end
