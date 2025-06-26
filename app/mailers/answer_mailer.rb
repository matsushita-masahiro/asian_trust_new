class AnswerMailer < ApplicationMailer
  default from: ENV['ONAMAE_MAIL_USER'] # 例: info@msworks.tokyo

  def notify_user(answer)
    @answer = answer
    @inquiry = answer.inquiry
    mail(
      to: @inquiry.email,
      subject: "【MS Works】お問い合わせへのご回答"
    )
  end
end
