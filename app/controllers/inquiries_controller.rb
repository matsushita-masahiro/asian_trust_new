# app/controllers/inquiries_controller.rb
class InquiriesController < ApplicationController
  def new
    @inquiry = Inquiry.new
  end

  def create
    @inquiry = Inquiry.new(inquiry_params)
    
    # reCAPTCHAの検証
    recaptcha_valid = verify_recaptcha
    Rails.logger.info "reCAPTCHA validation: #{recaptcha_valid}"
    
    if recaptcha_valid
      if @inquiry.save
        Rails.logger.info "Inquiry saved successfully"
        begin
          InquiryMailer.notify_admin(@inquiry).deliver_now
          InquiryMailer.thanks_to_user(@inquiry).deliver_now
          Rails.logger.info "Emails sent successfully"
          flash[:notice] = "お問い合わせありがとうございました。"
        rescue => e
          Rails.logger.error "Email sending failed: #{e.message}"
          flash[:notice] = "お問い合わせを受け付けました。（メール送信でエラーが発生しましたが、お問い合わせは正常に保存されました）"
        end
        redirect_to new_inquiry_path
      else
        Rails.logger.error "Inquiry save failed: #{@inquiry.errors.full_messages}"
        flash.now[:alert] = "入力内容に誤りがあります。"
        render :new
      end
    else
      Rails.logger.error "reCAPTCHA validation failed"
      @inquiry.errors.add(:base, "reCAPTCHAの認証に失敗しました。もう一度お試しください。")
      flash.now[:alert] = "入力内容に誤りがあります。"
      render :new
    end
  end

  private

  def inquiry_params
    params.require(:inquiry).permit(:name, :email, :phone, :message)
  end
end
