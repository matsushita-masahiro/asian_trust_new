# app/controllers/admin/base_controller.rb
class Admin::BaseController < ApplicationController
  
  before_action :authenticate
  before_action :authenticate_user!            # Deviseでログインしてるか
  before_action :require_admin                 # adminかどうか
  
  private

    def authenticate
      authenticate_or_request_with_http_basic('管理画面') do |username, password|
        username == ENV['ADMIN_USER'] && password == ENV['ADMIN_PASSWORD']
      end
    end
    
    def require_admin
      unless is_admin_user?(current_user)
        Rails.logger.warn "Unauthorized admin access attempt by user: #{current_user&.email} (ID: #{current_user&.id})"
        redirect_to root_path, alert: "管理者専用です"
      end
    end

    # ApplicationControllerと同じ管理者判定ロジック
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
      
      true
    end
end
