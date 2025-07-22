class Admin::SystemHealthController < Admin::BaseController
  def show
    @system_health = SystemHealthChecker.detailed_status
    @refresh_interval = 30 # 30秒間隔で自動更新
  end

  def check
    @system_health = SystemHealthChecker.new.check_all
    
    respond_to do |format|
      format.json { render json: @system_health }
      format.html { redirect_to admin_system_health_path, notice: 'システム状態を更新しました。' }
    end
  end

  def api_status
    # API用のシンプルなステータス
    health = SystemHealthChecker.cached_status
    
    render json: {
      status: health[:status],
      message: health[:message],
      timestamp: health[:checked_at]
    }
  end
end