# app/controllers/admin/users_controller.rb
class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :deactivate, :suspend, :reactivate, :certify]
  before_action :set_selected_month_range, only: [:show, :all_users]

  def index
    @users = User.includes(:referrer, :referrals, :level).order(:id)
  end

  def advisor_pre_list
    @advisor_pre_users = User.joins(:level)
                            .where(levels: { name: 'アドバイザー認定前' })
                            .includes(:level, :referrer)
                            .order(:created_at)
  end

  def all_users
    # 全ユーザーの階層構造を構築
    @all_users = User.includes(:referrer, :referrals, :level, purchases: { purchase_items: :product }).order(:id)
    
    # ルートユーザー（紹介者がいないユーザー）を取得してレベル順でソート
    root_users = @all_users.select { |user| user.referrer.nil? }
    
    # レベル順でソート（アジアビジネストラスト、総代理店、代理店...、クリニックを最後に）
    @root_users = root_users.sort_by do |user|
      case user.level&.name
      when 'アジアビジネストラスト'
        0
      when '総代理店'
        1
      when '代理店'
        2
      when 'アドバイザー'
        3
      when 'アドバイザー認定前'
        4
      when 'サポーター'
        5
      when 'サロン'
        6
      when 'クリニック'
        7  # クリニックを最後に
      when 'お客様'
        8
      else
        9
      end
    end
    
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

    # ✅ 住所情報を取得
    @invoice_base = @user.invoice_base
    
    # ✅ 申請中のレベル変更情報を取得
    @pending_application = LevelChangeApplication.where(user: @user, status: 'pending').first

    # ✅ 自身の購入履歴（選択月）
    @purchases = @user.purchases.in_period(@selected_month_start, @selected_month_end)

    # ✅ 下位ユーザーの購入履歴（選択月）
    descendant_ids = @user.descendants.pluck(:id)
    @descendant_purchases = Purchase.where(user_id: descendant_ids)
                                   .in_period(@selected_month_start, @selected_month_end)
                                   .includes(purchase_items: :product, user: [])

    # ✅ 自身 + 下位の購入履歴（選択月）
    @purchases_with_descendants = Purchase.where(user_id: [@user.id] + descendant_ids)
                                          .in_period(@selected_month_start, @selected_month_end)

    # 本人の売上を計算
    @own_sales_amount = @purchases.joins(purchase_items: :product).sum('purchase_items.seller_price * purchase_items.quantity')
    
    # 下位ユーザーの売上を計算
    descendant_purchases = Purchase.where(user_id: descendant_ids)
                                  .in_period(@selected_month_start, @selected_month_end)
    @descendant_sales_amount = descendant_purchases.joins(purchase_items: :product).sum('purchase_items.seller_price * purchase_items.quantity')
    
    # 総売上（本人 + 下位）
    @total_sales_amount = @own_sales_amount + @descendant_sales_amount
    
    # drill_downと同じ方法でインセンティブを計算
    @incentive_summary = calculate_incentive_summary_for_user(@user)

    # ✅ レベル別の子孫数を計算
    descendants = @user.descendants
    @level_counts = {
      total_agents: descendants.count { |u| u.level&.name == "総代理店" },
      agents: descendants.count { |u| u.level&.name == "代理店" },
      advisors: descendants.count { |u| u.level&.name == "アドバイザー" },
      salons: descendants.count { |u| u.level&.name == "サロン" },
      clinics: descendants.count { |u| u.level&.name == "クリニック" },
      customers: descendants.count { |u| u.level&.name == "お客様" }
    }

    # ✅ ref ごとの売上・ボーナスを算出
    @referral_stats = {}

    @referrals.each do |ref|
      # refとその子孫全体の売上（選択月）
      descendant_ids = ref.descendant_ids
      related_ids = [ref.id] + descendant_ids
      
      # ref経由で発生した全購入のうち、選択月に該当するもの
      descendant_purchases = Purchase
        .where(user_id: related_ids)
        .where(purchased_at: @selected_month_start..@selected_month_end)
      
      # 売上合計（refとその子孫全体）
      sales = descendant_purchases.joins(purchase_items: :product).sum('purchase_items.unit_price * purchase_items.quantity')

      # refのインセンティブ（選択月）
      bonus = ref.monthly_incentive_with_details(@selected_month)[:total] || 0

      @referral_stats[ref.id] = { sales: sales, bonus: bonus }
    end
  end

  def edit
    @levels = Level.where.not(name: 'アジアビジネストラスト').order(:value)
    @users = User.where.not(id: @user.id).order(:name, :email)
    @level_histories = @user.user_level_histories.includes(:level, :changed_by).recent.limit(10)
    
    # 申請中のレベル変更情報を取得
    @pending_application = LevelChangeApplication.where(user: @user, status: 'pending').first
    
    # セッションからエラーメッセージを取得
    @admin_password_error = session.delete(:admin_password_error)
    @level_change_reason_error = session.delete(:level_change_reason_error)
    @general_error = session.delete(:general_error)
    
    # セッションからフォームパラメータを取得
    @form_params = session.delete(:form_params) || {}
  end

  def update
    # レベル変更があるかチェック
    level_changed = params[:user][:level_id].present? && 
                   params[:user][:level_id].to_i != @user.level_id

    if level_changed
      # レベル変更申請の認証とバリデーション
      unless validate_level_change_application
        # エラーメッセージをセッションに保存
        session[:admin_password_error] = @admin_password_error if @admin_password_error.present?
        session[:level_change_reason_error] = @level_change_reason_error if @level_change_reason_error.present?
        session[:general_error] = @general_error if @general_error.present?
        
        # フォームの入力値を保持
        session[:form_params] = params.to_unsafe_h
        
        redirect_to edit_admin_user_path(@user) and return
      end
      
      # レベル変更申請処理
      if create_level_change_application
        redirect_to admin_user_path(@user), 
                   notice: "レベル変更申請が作成されました。変更は#{next_month_first_day.strftime('%Y年%m月%d日')}に実行されます。"
      else
        session[:general_error] = "レベル変更申請の作成に失敗しました。"
        session[:form_params] = params.to_unsafe_h
        redirect_to edit_admin_user_path(@user)
      end
    else
      # 通常の更新処理
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: 'ユーザー情報が更新されました。'
      else
        session[:form_params] = params.to_unsafe_h
        redirect_to edit_admin_user_path(@user)
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

  def certify
    # アドバイザー認定前のユーザーのみ認定可能
    unless @user.level&.name == 'アドバイザー認定前'
      redirect_to admin_user_path(@user), alert: 'このユーザーはアドバイザー認定前ではありません。'
      return
    end

    advisor_level = Level.find_by(name: 'アドバイザー')
    
    if advisor_level.nil?
      redirect_to admin_user_path(@user), alert: 'アドバイザーレベルが見つかりません。'
      return
    end

    ActiveRecord::Base.transaction do
      # レベル変更履歴を記録
      UserLevelHistory.create!(
        user: @user,
        from_level: @user.level,
        to_level: advisor_level,
        changed_by: current_user,
        reason: 'アドバイザー認定（管理者による昇格）',
        changed_at: Time.current
      )

      # ユーザーのレベルを更新
      @user.update!(level: advisor_level)
    end

    redirect_to admin_user_path(@user), 
                notice: "#{@user.name}さんをアドバイザーに認定しました。"
  rescue => e
    Rails.logger.error "アドバイザー認定エラー: #{e.message}"
    redirect_to admin_user_path(@user), 
                alert: "認定処理中にエラーが発生しました: #{e.message}"
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def set_selected_month_range
    selected_month = params[:month].presence || Date.today.strftime("%Y-%m")
    @selected_month = selected_month
    
    # drill_downと同じ方法で日付範囲を設定
    target_date = Date.strptime(selected_month, "%Y-%m")
    @selected_month_start = target_date.beginning_of_month
    @selected_month_end = target_date.end_of_month
    @selected_month_display = @selected_month_start.strftime("%Y/%m")
    
    Rails.logger.info "DEBUG: Date range setup - start: #{@selected_month_start}, end: #{@selected_month_end}"
  end

  def user_params
    params.require(:user).permit(:name, :email, :lstep_user_id, :level_id, :referred_by_id)
  end

  def validate_level_change_application
    # 管理者パスワードの確認
    admin_password = params[:admin_password]
    if admin_password.blank?
      @admin_password_error = "レベル変更申請には管理者パスワードが必要です。"
      return false
    end

    # 現在のユーザー（管理者）のパスワード認証
    unless current_user.valid_password?(admin_password)
      @admin_password_error = "管理者パスワードが正しくありません。"
      Rails.logger.info "Admin password validation failed for user #{current_user.id} (#{current_user.name})"
      return false
    end

    # 変更理由の確認
    change_reason = params[:level_change_reason]
    if change_reason.blank?
      @level_change_reason_error = "レベル変更申請の理由を入力してください。"
      return false
    end

    if change_reason.length < 10
      @level_change_reason_error = "レベル変更申請の理由は10文字以上で入力してください。"
      return false
    end

    # 自己変更の禁止
    if @user == current_user
      @general_error = "自分自身のレベルを変更申請することはできません。"
      return false
    end

    # 管理者権限の確認
    unless current_user.admin?
      @general_error = "レベル変更申請の権限がありません。"
      return false
    end

    # 重複申請チェック
    existing_application = LevelChangeApplication.where(
      user: @user,
      status: 'pending'
    ).first

    if existing_application
      @general_error = "このユーザーには既に未実行の申請が存在します。実行予定日: #{existing_application.scheduled_date.strftime('%Y年%m月%d日')}"
      return false
    end

    true
  end

  def create_level_change_application
    new_level_id = params[:user][:level_id].to_i
    change_reason = params[:level_change_reason]
    ip_address = request.remote_ip

    begin
      application = LevelChangeApplication.create!(
        user: @user,
        current_level_id: @user.level_id,
        target_level_id: new_level_id,
        applicant: current_user,
        reason: change_reason,
        scheduled_date: next_month_first_day,
        ip_address: ip_address
      )

      # 他のユーザー情報も更新（レベル以外）
      other_params = user_params.except(:level_id)
      @user.update(other_params) if other_params.present?

      # ログ記録と通知
      Rails.logger.info "Level change application created: User #{@user.id} (#{@user.name}) " \
                       "from #{@user.level.name} to #{Level.find(new_level_id).name} " \
                       "by #{current_user.id} (#{current_user.name}) " \
                       "from IP #{ip_address}. Scheduled: #{application.scheduled_date}"
      
      # 申請作成通知
      LevelChangeErrorNotifier.notify_application_created(application)

      true
    rescue => e
      Rails.logger.error "Level change application failed: #{e.message}"
      @error_message = "申請作成中にエラーが発生しました: #{e.message}"
      @user.errors.add(:base, @error_message)
      false
    end
  end

  def next_month_first_day
    Date.current.next_month.beginning_of_month
  end

  def calculate_incentive_summary_for_user(user)
    incentive_data = user.monthly_incentive_with_details(@selected_month)
    
    # 自己購入金額を計算
    own_sales_amount = calculate_own_sales_amount(user)
    
    # デバッグ情報
    Rails.logger.debug "=== Incentive Summary Debug ==="
    Rails.logger.debug "User: #{user.name}"
    Rails.logger.debug "Month: #{@selected_month}"
    Rails.logger.debug "Incentive data: #{incentive_data}"
    Rails.logger.debug "Total: #{incentive_data[:total]}"
    Rails.logger.debug "Own sales: #{incentive_data.dig(:details, :own_sales)}"
    Rails.logger.debug "Descendant sales: #{incentive_data.dig(:details, :descendant_sales)}"
    Rails.logger.debug "Own sales amount: #{own_sales_amount}"
    
    {
      total_incentive: incentive_data[:total] || 0,
      own_sales_incentive: incentive_data.dig(:details, :own_sales) || 0,
      descendant_incentive: incentive_data.dig(:details, :descendant_sales) || 0,
      own_sales_amount: own_sales_amount,
      direct_referrals_count: user.referrals.count,
      purchase_count: incentive_data.dig(:details, :purchase_count) || 0
    }
  end
  
  def calculate_own_sales_amount(user)
    # 指定期間内の自己購入金額を計算
    user.purchases
        .where(purchased_at: @selected_month_start..@selected_month_end)
        .joins(:purchase_items)
        .sum('purchase_items.unit_price * purchase_items.quantity')
  end
end
