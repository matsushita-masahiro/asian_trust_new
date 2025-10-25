class AddressesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_address, only: [:update, :destroy]
  before_action :set_user, only: [:create, :update, :destroy]
  before_action :check_access_permission, only: [:create, :update, :destroy]

  # POST /addresses
  def create
    @address = @user.addresses.find_or_initialize_by(address_type: address_params[:address_type])
    
    if @address.update(address_params)
      # カートから来た場合はfromパラメータ付きでユーザーページにリダイレクト
      if params[:from] == 'cart'
        redirect_to user_path(@user, from: 'cart'), notice: '住所を保存しました'
      else
        redirect_to user_path(@user), notice: '住所を保存しました'
      end
    else
      redirect_to_path = params[:from] == 'cart' ? user_path(@user, from: 'cart') : user_path(@user)
      redirect_to redirect_to_path, alert: "住所の保存に失敗しました: #{@address.errors.full_messages.join(', ')}"
    end
  end

  # PATCH/PUT /addresses/:id
  def update
    if @address.update(address_params)
      # カートから来た場合はfromパラメータ付きでユーザーページにリダイレクト
      if params[:from] == 'cart'
        redirect_to user_path(@user, from: 'cart'), notice: '住所を更新しました'
      else
        redirect_to user_path(@user), notice: '住所を更新しました'
      end
    else
      redirect_to_path = params[:from] == 'cart' ? user_path(@user, from: 'cart') : user_path(@user)
      redirect_to redirect_to_path, alert: "住所の更新に失敗しました: #{@address.errors.full_messages.join(', ')}"
    end
  end

  # DELETE /addresses/:id
  def destroy
    if @address.destroy
      render json: {
        success: true,
        message: '住所を削除しました'
      }
    else
      render json: {
        success: false,
        message: '住所の削除に失敗しました',
        errors: @address.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_address
    @address = Address.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: '住所が見つかりません'
    }, status: :not_found
  end

  def set_user
    @user = User.find(params[:user_id]) if params[:user_id]
    @user ||= @address&.user
    
    unless @user
      render json: {
        success: false,
        message: 'ユーザーが見つかりません'
      }, status: :not_found
    end
  end

  def check_access_permission
    return if can_access_user?(@user)
    
    render json: {
      success: false,
      message: '権限がありません'
    }, status: :forbidden
  end

  def can_access_user?(user)
    return false unless user
    
    # 管理者は全ユーザーの住所を管理可能
    return true if current_user.admin?
    
    # 自分自身の住所は管理可能
    return true if user == current_user
    
    false
  end

  def address_params
    params.require(:address).permit(:address_type, :postal_code, :address)
  end

  def format_address(address)
    parts = []
    parts << "〒#{address.postal_code}" if address.postal_code.present?
    parts << address.address if address.address.present?
    parts.join(' ')
  end
end