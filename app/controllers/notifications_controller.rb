class NotificationsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @notifications = current_user.notifications.recent.page(params[:page]).per(20)
    @unread_count = current_user.notifications.unread.count
  end

  def show
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read!
    
    # リンク先にリダイレクト
    if @notification.link_url.present?
      redirect_to @notification.link_url
    else
      redirect_to notifications_path, alert: 'リンク先が設定されていません。'
    end
  end
end
