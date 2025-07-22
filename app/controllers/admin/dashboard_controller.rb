class Admin::DashboardController < Admin::BaseController
  def index
    # システム状態チェック
    @system_health = SystemHealthChecker.cached_status
  end
end
