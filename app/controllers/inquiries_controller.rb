# app/controllers/inquiries_controller.rb
class InquiriesController < ApplicationController
  def new
    @inquiry = Inquiry.new
  end

  def create
    @inquiry = Inquiry.new(inquiry_params)
    if @inquiry.save
      InquiryMailer.notify_admin(@inquiry).deliver_now
      InquiryMailer.thanks_to_user(@inquiry).deliver_now
      flash[:notice] = "お問い合わせありがとうございました。"
      redirect_to new_inquiry_path
    else
      flash.now[:alert] = "入力内容に誤りがあります。"
      render :new
    end
  end

  private

  def inquiry_params
    params.require(:inquiry).permit(:name, :email, :phone, :message)
  end
end
