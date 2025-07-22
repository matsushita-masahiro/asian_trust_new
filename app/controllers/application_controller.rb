class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  before_action :set_selected_month

  private

  def set_selected_month
    @selected_month = params[:month].presence || Date.today.strftime("%Y-%m")
    @selected_month_start = Date.strptime(@selected_month, "%Y-%m").beginning_of_month
    @selected_month_end = Date.strptime(@selected_month, "%Y-%m").end_of_month
  end

  def log_access
    # 何もしない（ログイン成功時のコールバックで処理）
  end

  # Deviseのログイン成功時のコールバック
  def after_sign_in_path_for(resource)
    # ログイン成功時にアクセスログを記録
    AccessLog.log_access(request, resource)
    
    # 元のリダイレクト先を返す
    stored_location_for(resource) || root_path
  end
end
