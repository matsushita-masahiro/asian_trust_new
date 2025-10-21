class LevelChangeExecutorJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting level change execution job at #{Time.current}"
    
    # 実行対象の申請を取得
    applications = LevelChangeApplication.executable.includes(:user, :current_level, :target_level, :applicant)
    
    if applications.empty?
      Rails.logger.info "No level change applications to execute"
      return
    end

    Rails.logger.info "Found #{applications.count} applications to execute"
    
    success_count = 0
    error_count = 0
    
    applications.each do |application|
      begin
        execute_level_change(application)
        success_count += 1
        Rails.logger.info "Successfully executed application #{application.id} for user #{application.user.id}"
      rescue => e
        error_count += 1
        handle_execution_error(application, e)
        Rails.logger.error "Failed to execute application #{application.id}: #{e.message}"
      end
    end
    
    Rails.logger.info "Level change execution completed. Success: #{success_count}, Errors: #{error_count}"
    
    # 管理者に実行結果を通知
    notify_execution_result(success_count, error_count) if success_count > 0 || error_count > 0
  end

  private

  def execute_level_change(application)
    user = application.user
    new_level_id = application.target_level_id
    
    ApplicationRecord.transaction do
      # ユーザーのレベルを更新
      user.update!(level_id: new_level_id)
      
      # user_level_historiesテーブルに履歴を作成
      create_level_history(application)
      
      # 申請を完了状態に更新
      application.mark_as_completed!
      
      Rails.logger.info "Level changed for user #{user.id} from #{application.current_level.name} to #{application.target_level.name}"
    end
    
    # 成功通知をユーザーに送信
    send_completion_notification(application)
  end

  def create_level_history(application)
    user = application.user
    
    # 現在のアクティブな履歴を終了
    current_history = user.user_level_histories.where(effective_to: nil).first
    if current_history
      current_history.update!(effective_to: Time.current)
    end
    
    # 新しい履歴を作成
    user.user_level_histories.create!(
      level_id: application.target_level_id,
      previous_level_id: application.current_level_id,
      effective_from: Time.current,
      change_reason: "申請による自動変更: #{application.reason}",
      changed_by: application.applicant,
      ip_address: 'system_job'
    )
  end

  def handle_execution_error(application, error)
    application.mark_as_error!(error.message)
    
    # エラー通知システムを使用
    LevelChangeErrorNotifier.notify_execution_error(application, error)
  end

  def send_completion_notification(application)
    LevelChangeErrorNotifier.notify_application_completed(application)
  end

  def send_error_notification(application, error)
    # handle_execution_errorで処理済み
  end

  def notify_execution_result(success_count, error_count)
    LevelChangeErrorNotifier.notify_execution_result(success_count, error_count)
  end
end