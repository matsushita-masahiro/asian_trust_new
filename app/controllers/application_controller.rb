class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  before_action :set_selected_month
  after_action :log_access

  private

  def set_selected_month
    @selected_month = params[:month].presence || Date.today.strftime("%Y-%m")
    @selected_month_start = Date.strptime(@selected_month, "%Y-%m").beginning_of_month
    @selected_month_end = Date.strptime(@selected_month, "%Y-%m").end_of_month
  end

  def log_access
    # 管理画面以外のアクセスのみ記録
    return if request.path.start_with?('/admin/')
    
    # 現在のユーザーを取得（Deviseを使用している場合）
    current_user_for_log = respond_to?(:current_user) ? current_user : nil
    
    # アクセスログを記録
    AccessLog.log_access(request, current_user_for_log)
  end
end
