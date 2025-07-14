# app/controllers/admin/users_controller.rb
class Admin::UsersController < ApplicationController
  before_action :set_user

  def show
    # @user は set_user で読み込み済み
    # @referrer_chain = @user.ancestors.reverse
    # @referrals = @user.referrals.includes(:referrals)
    @referrer_chain = @user.ancestors
    @referrals = @user.referrals
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
