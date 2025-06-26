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
