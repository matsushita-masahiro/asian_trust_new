class ReferralInvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_referral_permission

  def new
    @referral_invitation = current_user.referral_invitations.build
    # ログインユーザーのレベルに応じて招待可能なレベルを設定
    @levels = get_invitable_levels(current_user.level&.value)
  end

  def create
    @referral_invitation = current_user.referral_invitations.build(referral_invitation_params)
    
    # レベル制限のチェック
    invitable_levels = get_invitable_levels(current_user.level&.value)
    if @referral_invitation.target_level && !invitable_levels.include?(@referral_invitation.target_level)
      @levels = invitable_levels
      @referral_invitation.errors.add(:target_level_id, 'は招待できないレベルです')
      render :new, status: :unprocessable_entity
      return
    end
    
    if @referral_invitation.save
      redirect_to referral_invitation_path(@referral_invitation), 
                  notice: '紹介QRが作成されました。'
    else
      @levels = get_invitable_levels(current_user.level&.value)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @referral_invitation = current_user.referral_invitations.find(params[:id])
    @referral_url = "#{request.protocol}#{request.host_with_port}/users/sign_up?ref=#{@referral_invitation.referral_token}"
    
    # QRコード生成
    require 'rqrcode'
    begin
      qr = RQRCode::QRCode.new(@referral_url)
      @qr_code_svg = qr.as_svg(
        offset: 0,
        color: '000',
        shape_rendering: 'crispEdges',
        module_size: 6,
        standalone: true
      )
    rescue => e
      Rails.logger.error "QR Code generation failed: #{e.message}"
      @qr_code_svg = nil
    end
  end

  def index
    @referral_invitations = current_user.referral_invitations
                                       .includes(:target_level, :invited_user)
                                       .order(created_at: :desc)
  end

  private

  def referral_invitation_params
    params.require(:referral_invitation).permit(:target_level_id)
  end

  def check_referral_permission
    # adminユーザーは紹介機能を利用可能
    return if current_user.admin?
    
    # 紹介機能を利用できないレベル: アドバイザー認定前(4), クリニック(6), サロン(7), お客様(8)
    unless current_user&.level&.value && ![4, 6, 7, 8].include?(current_user.level.value)
      redirect_to root_path, alert: 'あなたのレベルでは紹介機能をご利用いただけません。'
    end
  end

  def get_invitable_levels(user_level_value)
    # adminユーザーの場合はアジアビジネストラストを除く全レベルを招待可能
    if current_user.admin?
      return Level.where.not(name: 'アジアビジネストラスト')
    end
    
    case user_level_value
    when 1 # 総代理店
      # アドバイザー認定前、サポーター、クリニック、サロン、お客様（アドバイザーは管理者が認定するため除外）
      Level.where(name: ['アドバイザー認定前', 'サポーター', 'クリニック', 'サロン', 'お客様'])
    when 2 # 代理店  
      # アドバイザー認定前、サポーター、クリニック、サロン、お客様（アドバイザーは管理者が認定するため除外）
      Level.where(name: ['アドバイザー認定前', 'サポーター', 'クリニック', 'サロン', 'お客様'])
    when 3 # アドバイザー
      # アドバイザー認定前、サポーター、クリニック、サロン、お客様
      Level.where(name: ['アドバイザー認定前', 'サポーター', 'クリニック', 'サロン', 'お客様'])
    when 5 # サポーター（新しいvalue）
      # クリニック、サロン、お客様
      Level.where(name: ['クリニック', 'サロン', 'お客様'])
    else
      # クリニック、サロン、お客様の場合は何も表示しない
      Level.none
    end
  end
end