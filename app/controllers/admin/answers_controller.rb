# app/controllers/admin/answers_controller.rb
class Admin::AnswersController < Admin::BaseController
  before_action :set_inquiry

  def new
    @answer = @inquiry.answers.new
  end

  def create
    @inquiry = Inquiry.find(params[:inquiry_id])
    @answer = @inquiry.answers.build(answer_params)
  
    if @answer.save
      # ここでメール送信
      AnswerMailer.notify_user(@answer).deliver_now
      
      # ログインユーザーからのお問合せの場合、通知を作成
      if @inquiry.user_id.present?
        Notification.create!(
          user_id: @inquiry.user_id,
          notification_type: 'inquiry_answer',
          title: 'お問合せへの回答',
          message: "お問合せ「#{@inquiry.message.truncate(50)}」への回答がありました。",
          link_url: Rails.application.routes.url_helpers.inquiry_path(@inquiry)
        )
      end
  
      flash[:notice] = "回答を送信しました。"
      redirect_to admin_inquiry_path(@inquiry)
    else
      flash.now[:alert] = "回答の保存に失敗しました。"
      render :new
    end
  end


  private

  def set_inquiry
    @inquiry = Inquiry.find(params[:inquiry_id])
  end

  def answer_params
    params.require(:answer).permit(:content)
  end
end
