class ReferralsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_referral_permission

  def index
    # 直接URLを構築
    @referral_url = "#{request.protocol}#{request.host_with_port}/users/sign_up?ref=#{current_user.referral_token}"
    @referred_users = current_user.referrals.includes(:level)
    @total_referrals = @referred_users.count
  end

  def show
    @referred_user = current_user.referrals.find(params[:id])
  end

  def qr_code
    require 'rqrcode'
    
    # 直接URLを構築
    referral_url = "#{request.protocol}#{request.host_with_port}/users/sign_up?ref=#{current_user.referral_token}"
    qr = RQRCode::QRCode.new(referral_url)
    
    # SVG形式でQRコードを生成
    svg = qr.as_svg(
      offset: 0,
      color: '000',
      shape_rendering: 'crispEdges',
      module_size: 6,
      standalone: true
    )
    
    respond_to do |format|
      format.svg { render plain: svg, content_type: 'image/svg+xml' }
      format.html { @qr_code_svg = svg }
    end
  end

  private

  def check_referral_permission
    if current_user&.level&.value && [4, 5, 6].include?(current_user.level.value)
      redirect_to root_path, alert: 'あなたのレベルでは紹介機能をご利用いただけません。'
    end
  end
end