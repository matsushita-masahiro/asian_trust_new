class Users::RegistrationsController < ApplicationController
  before_action :set_referral_invitation, only: [:new, :create]

  def new
    if params[:ref].present? && @referral_invitation.nil?
      redirect_to root_path, alert: '無効な紹介リンクです。'
      return
    end
    
    if params[:ref].blank?
      redirect_to root_path, alert: '紹介者からの招待が必要です。'
      return
    end
    
    @user = User.new
    @minimum_password_length = User.password_length.min
  end

  def create
    if params[:ref].present? && @referral_invitation.nil?
      redirect_to new_user_registration_path, alert: '無効な紹介リンクです。'
      return
    end

    if @referral_invitation.nil?
      redirect_to root_path, alert: '紹介者からの招待が必要です。'
      return
    end

    # 暗証番号の確認
    if params[:passcode] != @referral_invitation.passcode
      @user = User.new(user_params)
      @minimum_password_length = User.password_length.min
      flash.now[:alert] = '暗証番号が正しくありません。'
      render :new, status: :unprocessable_entity
      return
    end

    # 招待の有効性確認
    unless @referral_invitation.active?
      redirect_to root_path, alert: 'この招待は既に使用済みか期限切れです。'
      return
    end

    @user = User.new(user_params)
    @user.referrer = @referral_invitation.referrer
    @user.level = @referral_invitation.target_level

    if @user.save
      # メール確認を自動で完了させる（開発環境用）
      @user.confirm if @user.respond_to?(:confirm)
      
      # 招待を使用済みにマーク
      @referral_invitation.mark_as_used!(@user)
      
      # ログイン処理
      sign_in(@user)
      
      flash[:notice] = "#{@referral_invitation.referrer.name || '紹介者'}さんからの紹介で登録が完了しました！"
      
      redirect_to root_path
    else
      @minimum_password_length = User.password_length.min
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_referral_invitation
    if params[:ref].present?
      @referral_invitation = ReferralInvitation.active.find_by(referral_token: params[:ref])
    end
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end