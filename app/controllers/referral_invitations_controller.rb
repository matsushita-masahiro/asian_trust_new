class ReferralInvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_referral_permission

  def new
    @referral_invitation = current_user.referral_invitations.build
    # 紹介者より低いレベルのみ選択可能
    @levels = Level.where('value > ?', current_user.level.value)
  end

  def create
    @referral_invitation = current_user.referral_invitations.build(referral_invitation_params)
    
    # レベル制限のチェック
    if @referral_invitation.target_level && @referral_invitation.target_level.value <= current_user.level.value
      @levels = Level.where('value > ?', current_user.level.value)
      @referral_invitation.errors.add(:target_level_id, 'は紹介者より低いレベルを選択してください')
      render :new, status: :unprocessable_entity
      return
    end
    
    if @referral_invitation.save
      redirect_to referral_invitation_path(@referral_invitation), 
                  notice: '紹介招待が作成されました。'
    else
      @levels = Level.where('value > ?', current_user.level.value)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @referral_invitation = current_user.referral_invitations.find(params[:id])
    @referral_url = "#{request.protocol}#{request.host_with_port}/users/sign_up?ref=#{@referral_invitation.referral_token}"
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
    unless current_user&.level&.value && ![4, 5, 6].include?(current_user.level.value)
      redirect_to root_path, alert: 'あなたのレベルでは紹介機能をご利用いただけません。'
    end
  end
end