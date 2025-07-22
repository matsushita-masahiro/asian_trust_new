class SystemHealthChecker
  attr_reader :status, :message, :details, :last_checked_at

  def initialize
    @status = :unknown
    @message = ""
    @details = {}
    @last_checked_at = nil
  end

  def check_all
    @last_checked_at = Time.current
    @details = {}
    
    checks = [
      check_database_connection,
      check_data_integrity,
      check_recent_errors,
      check_background_jobs,
      check_disk_space,
      check_memory_usage
    ]
    
    # 最も深刻な状態を採用
    @status = determine_overall_status(checks)
    @message = generate_status_message
    
    {
      status: @status,
      message: @message,
      details: @details,
      checked_at: @last_checked_at
    }
  end

  private

  def check_database_connection
    begin
      ActiveRecord::Base.connection.execute("SELECT 1")
      @details[:database] = { status: :normal, message: "データベース接続正常" }
      :normal
    rescue => e
      @details[:database] = { status: :error, message: "データベース接続エラー: #{e.message}" }
      :error
    end
  end

  def check_data_integrity
    begin
      # 重要なデータの整合性チェック
      user_count = User.count
      level_count = Level.count
      product_count = Product.count
      
      if user_count == 0
        @details[:data_integrity] = { status: :error, message: "ユーザーデータが存在しません" }
        return :error
      end
      
      if level_count == 0
        @details[:data_integrity] = { status: :error, message: "レベルデータが存在しません" }
        return :error
      end
      
      if product_count == 0
        @details[:data_integrity] = { status: :warning, message: "商品データが存在しません" }
        return :warning
      end
      
      # 孤立したユーザーチェック
      orphaned_users = User.joins(:level).where(levels: { id: nil }).count
      if orphaned_users > 0
        @details[:data_integrity] = { status: :warning, message: "レベル未設定のユーザーが#{orphaned_users}名います" }
        return :warning
      end
      
      @details[:data_integrity] = { 
        status: :normal, 
        message: "データ整合性正常 (ユーザー: #{user_count}, レベル: #{level_count}, 商品: #{product_count})" 
      }
      :normal
    rescue => e
      @details[:data_integrity] = { status: :error, message: "データ整合性チェックエラー: #{e.message}" }
      :error
    end
  end

  def check_recent_errors
    begin
      # Heroku環境では永続的なログファイルが存在しないため、
      # 代替手段でエラー監視を行う
      if heroku_environment?
        # Herokuログは外部サービス（Papertrail等）で監視することを推奨
        @details[:error_logs] = { 
          status: :normal, 
          message: "Heroku環境: ログ監視は外部サービスで実施" 
        }
        return :normal
      else
        # 通常環境でのログファイルチェック
        log_file = Rails.root.join('log', "#{Rails.env}.log")
        
        if File.exist?(log_file)
          recent_errors = count_recent_errors(log_file)
          
          if recent_errors > 100
            @details[:error_logs] = { status: :error, message: "過去24時間で#{recent_errors}件のエラーが発生" }
            return :error
          elsif recent_errors > 10
            @details[:error_logs] = { status: :warning, message: "過去24時間で#{recent_errors}件のエラーが発生" }
            return :warning
          else
            @details[:error_logs] = { status: :normal, message: "エラーログ正常 (#{recent_errors}件)" }
            return :normal
          end
        else
          @details[:error_logs] = { status: :normal, message: "ログファイル未使用環境" }
          return :normal
        end
      end
    rescue => e
      @details[:error_logs] = { status: :warning, message: "エラーログチェック失敗: #{e.message}" }
      :warning
    end
  end

  def check_background_jobs
    begin
      # Sidekiq や Active Job の状態をチェック
      if defined?(Sidekiq)
        stats = Sidekiq::Stats.new
        failed_jobs = stats.failed
        
        if failed_jobs > 50
          @details[:background_jobs] = { status: :error, message: "失敗したジョブが#{failed_jobs}件あります" }
          return :error
        elsif failed_jobs > 10
          @details[:background_jobs] = { status: :warning, message: "失敗したジョブが#{failed_jobs}件あります" }
          return :warning
        else
          @details[:background_jobs] = { status: :normal, message: "バックグラウンドジョブ正常" }
          return :normal
        end
      else
        @details[:background_jobs] = { status: :normal, message: "バックグラウンドジョブ未使用" }
        :normal
      end
    rescue => e
      @details[:background_jobs] = { status: :warning, message: "バックグラウンドジョブチェック失敗: #{e.message}" }
      :warning
    end
  end

  def check_disk_space
    begin
      # ディスク使用量チェック（Unix系のみ）
      if RUBY_PLATFORM.include?('linux') || RUBY_PLATFORM.include?('darwin')
        disk_usage = `df -h #{Rails.root}`.split("\n")[1].split[4].to_i
        
        if disk_usage > 95
          @details[:disk_space] = { status: :error, message: "ディスク使用量が#{disk_usage}%です" }
          return :error
        elsif disk_usage > 90
          @details[:disk_space] = { status: :warning, message: "ディスク使用量が#{disk_usage}%です" }
          return :warning
        else
          @details[:disk_space] = { status: :normal, message: "ディスク使用量正常 (#{disk_usage}%)" }
          return :normal
        end
      else
        @details[:disk_space] = { status: :normal, message: "ディスクチェック未対応" }
        :normal
      end
    rescue => e
      @details[:disk_space] = { status: :warning, message: "ディスクチェック失敗: #{e.message}" }
      :warning
    end
  end

  def check_memory_usage
    begin
      # メモリ使用量チェック
      if defined?(GC)
        gc_stat = GC.stat
        heap_used = gc_stat[:heap_live_slots]
        heap_total = gc_stat[:heap_available_slots]
        
        if heap_total > 0
          usage_percent = (heap_used.to_f / heap_total * 100).round(1)
          
          if usage_percent > 90
            @details[:memory_usage] = { status: :warning, message: "メモリ使用量が#{usage_percent}%です" }
            return :warning
          else
            @details[:memory_usage] = { status: :normal, message: "メモリ使用量正常 (#{usage_percent}%)" }
            return :normal
          end
        end
      end
      
      @details[:memory_usage] = { status: :normal, message: "メモリチェック完了" }
      :normal
    rescue => e
      @details[:memory_usage] = { status: :warning, message: "メモリチェック失敗: #{e.message}" }
      :warning
    end
  end

  def count_recent_errors(log_file)
    # 過去24時間のエラーを数える
    twenty_four_hours_ago = 24.hours.ago
    error_count = 0
    
    File.readlines(log_file).reverse.each do |line|
      # ログの日時を解析
      if line.match(/\A[A-Z], \[(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+) #\d+\]/)
        log_time = Time.parse($1) rescue nil
        break if log_time && log_time < twenty_four_hours_ago
        
        # エラーレベルのログをカウント
        error_count += 1 if line.include?('ERROR') || line.include?('FATAL')
      end
    end
    
    error_count
  rescue
    0
  end

  def determine_overall_status(checks)
    return :error if checks.include?(:error)
    return :warning if checks.include?(:warning)
    :normal
  end

  def generate_status_message
    case @status
    when :normal
      "システム正常稼働中"
    when :warning
      "軽微な問題が検出されました"
    when :error
      "重大な問題が発生しています"
    else
      "システム状態不明"
    end
  end

  # キャッシュ機能
  def self.cached_status
    Rails.cache.fetch("system_health_status", expires_in: 5.minutes) do
      new.check_all
    end
  end

  # 詳細情報取得
  def self.detailed_status
    new.check_all
  end

  private

  # Heroku環境かどうかを判定
  def heroku_environment?
    ENV['DYNO'].present? || ENV['HEROKU_APP_NAME'].present?
  end
end