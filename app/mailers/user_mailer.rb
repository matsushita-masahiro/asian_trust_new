# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  def send_password_reset_link(user, token)
    @user = user
    @reset_url = edit_user_password_url(reset_password_token: token)
    mail(to: @user.email, subject: "【重要】パスワード再設定のお願い")
  end
end
