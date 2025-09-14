# app/controllers/admin/users_controller.rb
class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :deactivate, :suspend, :reactivate]
  before_action :set_selected_month_range, only: [:show, :all_users]

  def index
    @users = User.includes(:referrer, :referrals).order(:id)
  end

  def all_users
    # 全ユーザーの階層構造を構築
    @all_users = User.includes(:referrer, :referrals, :level, purchases: { purchase_items: :product }).order(:id)
    
    # ルートユーザー（紹介者がいないユーザー）を取得
    @root_users = @all_users.select { |user| user.referrer.nil? }
    
    # 今月と先月の期間を動的に設定
    @current_month = Date.current.beginning_of_month
    @last_month = @current_month - 1.month
    
    current_month_start = @current_month
    current_month_end = @current_month.end_of_month
    last_month_start = @last_month
    last_month_end = @last_month.end_of_month
    
    # 表示用の月名
    @current_month_name = @current_month.strftime("%m月")
    @last_month_name = @last_month.strftime("%m月")
    
    # 各ユーザーの売上とボーナスを計算（今月と先月）
    @user_stats = {}
    
    @all_users.each do |user|
      # 今月の売上とボーナス
      current_purchases = user.purchases.where(purchased_at: current_month_start..current_month_end)
      current_sales = current_purchases.joins(purchase_items: :product).sum('purchase_items.unit_price * purchase_items.quantity')
      current_bonus = user.respond_to?(:bonus_in_period) ? user.bonus_in_period(current_month_start, current_month_end) : 0
      
      # 先月の売上とボーナス
      last_purchases = user.purchases.where(purchased_at: last_month_start..last_month_end)
      last_sales = last_purchases.joins(purchase_items: :product).sum('purchase_items.unit_price * purchase_items.quantity')
      last_bonus = user.respond_to?(:bonus_in_period) ? user.bonus_in_period(last_month_start, last_month_end) : 0
      
      @user_stats[user.id] = {
        current: { sales: current_sales, bonus: current_bonus },
        last: { sales: last_sales, bonus: last_bonus }
      }
    end
  end

  def show
    @referrer_chain = @user.ancestors
    @referrals = @user.referrals

    # ✅ 自身の購入履歴（選択月）
    @purchases = @user.purchases.in_period(@selected_month_start, @selected_month_end)

    # ✅ 自身 + 下位の購入履歴（選択月）
    descendant_ids = @user.descendants.pluck(:id)
    @purchases_with_descendants = Purchase.where(user_id: [@user.id] + descendant_ids)
                                          .in_period(@selected_month_start, @selected_month_end)

    @total_sales_amount = @purchases_with_descendants.joins(purchase_items: :product).sum('purchase_items.unit_price * purchase_items.quantity')

    # ✅ ref ごとの売上・ボーナスを算出
    @referral_stats = {}

    @referrals.each do |ref|
      # ref自身の購入（選択月）
      purchases = ref.purchases.in_period(@selected_month_start, @selected_month_end)
      sales = purchases.joins(purchase_items: :product).sum('purchase_items.unit_price * purchase_items.quantity')

      # ✅ refに起因する全購入（その子孫含む）
      descendant_ids = ref.descendant_ids
      related_ids = [ref.id] + descendant_ids

      # ✅ ref経由で発生した全購入のうち、選択月に該当するもの
      descendant_purchases = Purchase
        .where(user_id: related_ids)
        .where(purchased_at: @selected_month_start..@selected_month_end)

      # ✅ @userにとってのボーナス合計（このrefツリーによるものだけ）
      bonus = descendant_purchases.sum { |p| @user.bonus_for_purchase(p) }

      @referral_stats[ref.id] = { sales: sales, bonus: bonus }
    end
  end

  def edit
    @levels = Level.where.not(name: 'アジアビジネストラスト').order(:value)
    @users = User.where.not(id: @user.id).order(:name, :email)
    @level_histories = @user.user_level_histories.includes(:level, :changed_by).recent.limit(10)
  end

  def update
    # レベル変更があるかチェック
    level_changed = params[:user][:level_id].present? && 
                   params[:user][:level_id].to_i != @user.level_id

    if level_changed
      # レベル変更時の認証とバリデーション
      unless validate_level_change
        render :edit and return
      end
      
      # レベル変更処理
      if process_level_change
        redirect_to admin_user_path(@user), 
                   notice: "ユーザー情報とレベルが更新されました。レベル変更履歴が記録されました。"
      else
        flash.now[:error] = "レベル変更に失敗しました。"
        render :edit
      end
    else
      # 通常の更新処理
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: 'ユーザー情報が更新されました。'
      else
        render :edit
      end
    end
  end

  def deactivate
    @user = User.find(params[:id])
    @user.update!(status: 'inactive')
    redirect_to admin_user_path(@user), notice: 'ユーザーを退会処理しました。'
  end

  def suspend
    @user = User.find(params[:id])
    @user.update!(status: 'suspended')
    redirect_to admin_user_path(@user), notice: 'ユーザーを停止処分にしました。'
  end

  def reactivate
    @user = User.find(params[:id])
    @user.update!(status: 'active')
    redirect_to admin_user_path(@user), notice: 'ユーザーを再アクティブ化しました。'
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def set_selected_month_range
    selected_month = params[:month].presence || Date.today.strftime("%Y-%m")
    @selected_month = selected_month
    @selected_month_start = Date.strptime(selected_month, "%Y-%m").beginning_of_month
    @selected_month_end   = Date.strptime(selected_month, "%Y-%m").end_of_month
    @selected_month_display = @selected_month_start.strftime("%Y/%m")
  end

  def user_params
    params.require(:user).permit(:name, :email, :lstep_user_id, :level_id, :referred_by_id)
  end

  def validate_level_change
    # 管理者パスワードの確認
    admin_password = params[:admin_password]
    if admin_password.blank?
      flash.now[:error] = "レベル変更には管理者パスワードが必要です。"
      return false
    end

    # 現在のユーザー（管理者）のパスワード認証
    unless current_user.valid_password?(admin_password)
      flash.now[:error] = "管理者パスワードが正しくありません。"
      return false
    end

    # 変更理由の確認
    change_reason = params[:level_change_reason]
    if change_reason.blank?
      flash.now[:error] = "レベル変更の理由を入力してください。"
      return false
    end

    # 自己変更の禁止
    if @user == current_user
      flash.now[:error] = "自分自身のレベルを変更することはできません。"
      return false
    end

    # 管理者権限の確認
    unless current_user.admin?
      flash.now[:error] = "レベル変更の権限がありません。"
      return false
    end

    true
  end

  def process_level_change
    new_level_id = params[:user][:level_id].to_i
    change_reason = params[:level_change_reason]
    ip_address = request.remote_ip

    # レベル変更履歴の更新
    success = @user.update_level_history(
      new_level_id,
      change_reason,
      current_user,
      ip_address
    )

    if success
      # 他のユーザー情報も更新
      other_params = user_params.except(:level_id)
      @user.update(other_params) if other_params.present?
      
      # ログ記録
      Rails.logger.info "Level changed: User #{@user.id} (#{@user.name}) " \
                       "from #{@user.level_id} to #{new_level_id} " \
                       "by #{current_user.id} (#{current_user.name}) " \
                       "from IP #{ip_address}. Reason: #{change_reason}"
      
      true
    else
      false
    end
  end
end
