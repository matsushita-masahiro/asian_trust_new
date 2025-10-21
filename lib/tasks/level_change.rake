namespace :level_change do
  desc "Execute pending level change applications"
  task execute: :environment do
    lock_file = Rails.root.join('tmp', 'level_change_execution.lock')
    
    # 重複実行防止
    if File.exist?(lock_file)
      lock_time = File.mtime(lock_file)
      if Time.current - lock_time < 1.hour
        puts "Level change execution is already running or was recently executed. Skipping."
        exit 0
      else
        # 1時間以上古いロックファイルは削除
        File.delete(lock_file)
        puts "Removed stale lock file"
      end
    end
    
    begin
      # ロックファイル作成
      File.write(lock_file, Process.pid.to_s)
      puts "Starting level change execution task at #{Time.current}"
      
      LevelChangeExecutorJob.perform_now
      puts "Level change execution task completed successfully"
      
    rescue => e
      puts "Level change execution task failed: #{e.message}"
      Rails.logger.error "Level change execution task failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    ensure
      # ロックファイル削除
      File.delete(lock_file) if File.exist?(lock_file)
    end
  end
  
  desc "Show pending level change applications"
  task show_pending: :environment do
    applications = LevelChangeApplication.executable.includes(:user, :current_level, :target_level, :applicant)
    
    if applications.empty?
      puts "No pending level change applications found"
    else
      puts "Found #{applications.count} pending applications:"
      applications.each do |app|
        puts "  ID: #{app.id}, User: #{app.user_name}, Change: #{app.current_level.name} -> #{app.target_level.name}, Scheduled: #{app.scheduled_date}"
      end
    end
  end
end