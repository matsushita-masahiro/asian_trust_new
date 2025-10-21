class LevelChangeErrorNotifier
  class << self
    def notify_execution_error(application, error)
      Rails.logger.error "Level change execution error for application #{application.id}: #{error.message}"
      Rails.logger.error error.backtrace.join("\n") if error.backtrace
      
      # 管理者にエラー通知メール送信（実装予定）
      # AdminMailer.level_change_error(application, error).deliver_now
      
      # 緊急度の高いエラーの場合は即座に通知
      if critical_error?(error)
        notify_critical_error(application, error)
      end
    end
    
    def notify_execution_result(success_count, error_count, applications = [])
      message = "Level change execution completed: #{success_count} success, #{error_count} errors"
      Rails.logger.info message
      
      if error_count > 0
        Rails.logger.warn "#{error_count} applications failed to execute"
        # 管理者に実行結果通知メール送信（実装予定）
        # AdminMailer.level_change_execution_result(success_count, error_count, applications).deliver_now
      end
    end
    
    def notify_application_created(application)
      Rails.logger.info "Level change application created: ID #{application.id}, User: #{application.user_name}, Change: #{application.level_change_description}"
      
      # ユーザーに申請作成通知メール送信（実装予定）
      # UserMailer.level_change_application_created(application).deliver_now
    end
    
    def notify_application_completed(application)
      Rails.logger.info "Level change application completed: ID #{application.id}, User: #{application.user_name}"
      
      # ユーザーに変更完了通知メール送信（実装予定）
      # UserMailer.level_change_completed(application).deliver_now
    end
    
    def notify_application_cancelled(application, cancelled_by)
      Rails.logger.info "Level change application cancelled: ID #{application.id}, User: #{application.user_name}, Cancelled by: #{cancelled_by.name}"
      
      # ユーザーに申請キャンセル通知メール送信（実装予定）
      # UserMailer.level_change_application_cancelled(application, cancelled_by).deliver_now
    end
    
    private
    
    def critical_error?(error)
      # データベース接続エラーやシステムエラーなど、緊急度の高いエラーを判定
      critical_error_classes = [
        ActiveRecord::ConnectionNotEstablished,
        ActiveRecord::StatementInvalid,
        SystemExit,
        NoMemoryError
      ]
      
      critical_error_classes.any? { |klass| error.is_a?(klass) }
    end
    
    def notify_critical_error(application, error)
      Rails.logger.fatal "CRITICAL: Level change execution failed with critical error for application #{application.id}: #{error.message}"
      
      # 緊急通知の実装（Slack、SMS、メールなど）
      # 実装例：
      # SlackNotifier.send_critical_alert("Level change critical error", error.message)
      # SmsNotifier.send_emergency_alert(admin_phone_numbers, "Level change system error")
    end
  end
end