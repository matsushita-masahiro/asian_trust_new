class AccessLog < ApplicationRecord
  belongs_to :user, optional: true

  scope :today, -> { where(accessed_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :this_week, -> { where(accessed_at: 1.week.ago..Time.current) }
  scope :this_month, -> { where(accessed_at: 1.month.ago..Time.current) }
  
  # 管理画面以外のアクセスのみ
  scope :user_access, -> { where.not(path: /^\/admin/) }
  
  def self.log_access(request, user = nil)
    # 静的ファイルやAPIは除外
    return if request.path.match?(/\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf)$/) ||
              request.path.start_with?('/api/') ||
              request.path.start_with?('/assets/') ||
              request.path.start_with?('/rails/active_storage/')
    
    create!(
      ip_address: request.remote_ip,
      path: request.path,
      user_agent: request.user_agent,
      user: user,
      accessed_at: Time.current
    )
  rescue => e
    Rails.logger.error "アクセスログ記録エラー: #{e.message}"
  end
end
