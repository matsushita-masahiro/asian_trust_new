# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  before_action :check_ip_attempts, only: [:create]
  after_action :track_failed_attempt, only: [:create]

  # POST /resource/sign_in
  def create
    super do |resource|
      if resource.persisted?
        # ログイン成功時にIPアドレスの失敗回数をリセット
        Rails.cache.delete("failed_attempts_#{request.remote_ip}")
        Rails.logger.info "Successful login for #{resource.email} from IP: #{request.remote_ip}"
      end
    end
  end

  protected

  # IPアドレスベースの制限チェック
  def check_ip_attempts
    ip = request.remote_ip
    attempts = Rails.cache.read("failed_attempts_#{ip}") || 0
    
    if attempts >= 10 # IPアドレスあたり10回まで
      Rails.logger.warn "IP #{ip} blocked due to too many failed attempts (#{attempts})"
      flash[:alert] = "このIPアドレスからの接続が一時的に制限されています。しばらく時間をおいてからお試しください。"
      redirect_to new_user_session_path and return
    end
  end

  # 失敗時のIPアドレス追跡
  def track_failed_attempt
    unless user_signed_in?
      ip = request.remote_ip
      attempts = Rails.cache.read("failed_attempts_#{ip}") || 0
      attempts += 1
      
      # 1時間でリセット
      Rails.cache.write("failed_attempts_#{ip}", attempts, expires_in: 1.hour)
      
      Rails.logger.warn "Failed login attempt from IP: #{ip} (attempt #{attempts}/10)"
      
      if attempts >= 8 # 警告
        flash[:alert] = "ログインに失敗しました。あと#{10 - attempts}回失敗すると一時的にアクセスが制限されます。"
      end
    end
  end
end
