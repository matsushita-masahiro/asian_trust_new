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
    debug_lines = []
    
    begin
      # ログファイルを逆順で読み込み（最新のログから）
      lines = File.readlines(log_file).reverse
      
      lines.each do |line|
        # 今日の日付が含まれていない場合はスキップ
        next unless line.include?(today)
        
        # デバッグ用に最初の10行を保存
        debug_lines << line.strip if debug_lines.size < 10
        
        # Started GETを含み、管理画面以外のアクセスをカウント
        if line.include?("Started GET") && !line.include?("/admin/")
          # 静的ファイルやAPIエンドポイントを除外
          unless line.match?(/\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf)/) ||
                 line.include?("/api/") ||
                 line.include?("/assets/") ||
                 line.include?("/rails/active_storage/")
            count += 1
          end
        end
        
        # 今日より古い日付に到達したら終了
        break if count > 0 && !line.include?(today)
      end
      
      # デバッグ情報をログに出力
      Rails.logger.info "今日のアクセス数: #{count}"
      Rails.logger.info "デバッグ用ログサンプル: #{debug_lines.first(3).join(' | ')}"
      
    rescue => e
      Rails.logger.error "アクセス数取得エラー: #{e.message}"
      return 0
    end
    
    count
  end
end
