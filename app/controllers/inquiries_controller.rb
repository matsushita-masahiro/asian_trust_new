# app/controllers/inquiries_controller.rb
class InquiriesController < ApplicationController
  def new
    @inquiry = Inquiry.new
  end

  def create
    @inquiry = Inquiry.new(inquiry_params)
    
    # reCAPTCHAの検証
    recaptcha_valid = verify_recaptcha
    
    if recaptcha_valid && @inquiry.save
      InquiryMailer.notify_admin(@inquiry).deliver_now
      InquiryMailer.thanks_to_user(@inquiry).deliver_now
      flash[:notice] = "お問い合わせありがとうございました。"
      redirect_to new_inquiry_path
    else
      # reCAPTCHAが失敗した場合のエラーメッセージを追加
      unless recaptcha_valid
        @inquiry.errors.add(:base, "reCAPTCHAの認証に失敗しました。もう一度お試しください。")
      end
      flash.now[:alert] = "入力内容に誤りがあります。"
      render :new
    end
  end

  private

  def inquiry_params
    params.require(:inquiry).permit(:name, :email, :phone, :message)
  end
end
