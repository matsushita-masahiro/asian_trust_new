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
    
    Rails.logger.info "=== アクセス数カウント開始 ==="
    Rails.logger.info "ログファイル: #{log_file}"
    Rails.logger.info "ファイル存在: #{File.exist?(log_file)}"
    
    return 0 unless File.exist?(log_file)

    # 今日の日付（UTC）
    today = Date.current.strftime("%Y-%m-%d")
    # 昨日の日付も含める（タイムゾーンの違いを考慮）
    yesterday = (Date.current - 1.day).strftime("%Y-%m-%d")
    
    Rails.logger.info "検索対象日付: #{today}, #{yesterday}"
    
    count = 0
    debug_lines = []
    total_lines = 0
    
    begin
      File.foreach(log_file) do |line|
        total_lines += 1
        
        # 今日または昨日の日付が含まれているかチェック
        date_match = line.include?(today) || line.include?(yesterday)
        next unless date_match
        
        # デバッグ用に最初の5行を保存
        if debug_lines.size < 5
          debug_lines << line.strip[0..100] # 最初の100文字のみ
        end
        
        # Started GETを含み、管理画面以外のアクセスをカウント
        if line.include?("Started GET") && !line.include?("/admin/")
          # 静的ファイルやAPIエンドポイントを除外
          unless line.match?(/\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf)/) ||
                 line.include?("/api/") ||
                 line.include?("/assets/") ||
                 line.include?("/rails/active_storage/")
            count += 1
            Rails.logger.info "カウント対象: #{line.strip[0..150]}"
          end
        end
      end
      
      # デバッグ情報をログに出力
      Rails.logger.info "=== アクセス数カウント結果 ==="
      Rails.logger.info "総行数: #{total_lines}"
      Rails.logger.info "今日のアクセス数: #{count}"
      Rails.logger.info "デバッグ用ログサンプル:"
      debug_lines.each_with_index do |line, i|
        Rails.logger.info "  #{i+1}: #{line}"
      end
      Rails.logger.info "=== カウント終了 ==="
      
    rescue => e
      Rails.logger.error "アクセス数取得エラー: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      return 0
    end
    
    count
  end
end
