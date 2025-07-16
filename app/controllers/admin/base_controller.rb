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
      unless current_user&.admin?
        redirect_to root_path, alert: "管理者専用です"
      end
    end
end
