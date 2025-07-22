class Admin::DashboardController < Admin::BaseController
  def index
    # システム状態チェック
    @system_health = SystemHealthChecker.cached_status
    
    # 今日のアクセス数を取得
    @today_access_count = get_today_access_count
  end

  private

  def get_today_access_count
    # production.logから今日のアクセス数を取得
    log_file = Rails.root.join('log', "#{Rails.env}.log")
    return 0 unless File.exist?(log_file)

    today = Date.current.strftime("%Y-%m-%d")
    count = 0
    
    begin
      File.foreach(log_file) do |line|
        if line.include?(today) && line.include?("Started GET") && !line.include?("/admin/")
          count += 1
        end
      end
    rescue => e
      Rails.logger.error "アクセス数取得エラー: #{e.message}"
      return 0
    end
    
    count
  end
end
