class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_selected_month_range
  # 現在のユーザーのマイページ
  def mypage
    @user = current_user
  end

  # 下位ユーザーの詳細（再帰的に遷移可能）
  def show
    @user = User.find(params[:id])

    unless current_user.descendants.include?(@user) || @user == current_user
      redirect_to mypage_path, alert: "アクセス権がありません。"
    end
  end
  
  private
    def set_selected_month_range
      selected_month = params[:month].presence || Date.today.strftime("%Y-%m")
      @selected_month = selected_month
      @selected_month_start = Date.strptime(selected_month, "%Y-%m").beginning_of_month
      @selected_month_end   = Date.strptime(selected_month, "%Y-%m").end_of_month
    end
end
