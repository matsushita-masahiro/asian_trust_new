class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  before_action :set_selected_month

  private

  def set_selected_month
    @selected_month = params[:month].presence || Date.today.strftime("%Y-%m")
    @selected_month_start = Date.strptime(@selected_month, "%Y-%m").beginning_of_month
    @selected_month_end = Date.strptime(@selected_month, "%Y-%m").end_of_month
  end

  def log_access
    # 何もしない（ログイン成功時のコールバックで処理）
  end

  # Deviseのログイン成功時のコールバック
  def after_sign_in_path_for(resource)
    # ログイン成功時にアクセスログを記録
    log_successful_login(resource)
    
    # adminユーザーの場合はadmin/dashboardにリダイレクト
    if is_admin_user?(resource)
      Rails.logger.info "Admin user #{resource.email} redirected to admin dashboard"
      admin_root_path
    else
      # 一般ユーザーは元のリダイレクト先を返す
      stored_location_for(resource) || root_path
    end
  end

  # 管理者権限の判定（複合的なチェック）
  def is_admin_user?(user)
    return false unless user&.admin?
    
    # 追加のセキュリティチェック
    # 1. 特定のメールドメインチェック
    allowed_admin_domains = ['abt-saisei.com']
    return false unless allowed_admin_domains.any? { |domain| user.email.end_with?("@#{domain}") }
    
    # 2. アカウント状態チェック
    return false unless user.active?
    
    # 3. レベルチェック（最上位レベルのみ）
    return false unless user.level&.name == 'アジアビジネストラスト'
    
    # 4. 最後のログイン時間チェック（オプション）
    # return false if user.last_sign_in_at && user.last_sign_in_at < 90.days.ago
    
    true
  end

  # ログイン成功時のログ記録
  def log_successful_login(user)
    Rails.logger.info "LOGIN SUCCESS: User #{user.email} (ID: #{user.id}) from IP: #{request.remote_ip}, User-Agent: #{request.user_agent}"
  end

  # 不審なアクセスの検出
  def detect_suspicious_activity
    ip = request.remote_ip
    user_agent = request.user_agent
    
    # 短時間での大量アクセスをチェック
    access_count = Rails.cache.read("access_count_#{ip}") || 0
    access_count += 1
    Rails.cache.write("access_count_#{ip}", access_count, expires_in: 1.minute)
    
    if access_count > 60 # 1分間に60回以上のアクセス
      Rails.logger.warn "SUSPICIOUS ACTIVITY: High frequency access from IP: #{ip}, User-Agent: #{user_agent}"
    end
  end
end
