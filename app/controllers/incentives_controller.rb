class IncentivesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_incentive_permission
  before_action :set_date_range
  
  def index
    # メインのインセンティブ画面
    # 自分の直下位ユーザー一覧と売上表示
    @direct_referrals = current_user.referrals
    @incentive_summary = calculate_incentive_summary
    @hierarchy_data = calculate_hierarchy_sales(current_user)
  end
  
  def show
    # 特定ユーザーの詳細インセンティブ表示
    @target_user = User.find(params[:id])
    
    # アクセス権限チェック - 自分または自分の下位ユーザーのみアクセス可能
    unless can_access_user?(@target_user)
      flash[:alert] = "アクセス権限がありません"
      redirect_to incentives_path and return
    end
    
    @detailed_incentives = calculate_detailed_incentives(@target_user)
  end
  
  def drill_down
    # 階層ドリルダウン機能
    @target_user = User.find(params[:id])
    
    unless can_access_user?(@target_user)
      flash[:alert] = "アクセス権限がありません"
      redirect_to incentives_path and return
    end
    
    # indexビューで必要なインスタンス変数を設定
    @direct_referrals = @target_user.referrals
    @incentive_summary = calculate_incentive_summary_for_user(@target_user)
    @hierarchy_data = calculate_hierarchy_sales(@target_user)
    
    # 日付関連の変数も設定（set_date_rangeで設定されるが、念のため確認）
    # set_date_rangeはbefore_actionで実行されるので、@target_date等は既に設定済み
    
    render :index
  end
  
  def hierarchy
    # 階層表示用のAJAXエンドポイント
    @target_user = params[:user_id] ? User.find(params[:user_id]) : current_user
    
    unless can_access_user?(@target_user)
      head :forbidden and return
    end
    
    @hierarchy_data = calculate_hierarchy_sales(@target_user)
    render partial: 'hierarchy_table', locals: { user: @target_user, data: @hierarchy_data }
  end
  
  def export
    # CSV/PDFエクスポート機能
    @target_user = params[:id] ? User.find(params[:id]) : current_user
    
    unless can_access_user?(@target_user)
      flash[:alert] = "アクセス権限がありません"
      redirect_to incentives_path and return
    end
    
    format = params[:format] || 'csv'
    
    case format
    when 'csv'
      export_csv(@target_user)
    when 'pdf'
      export_pdf(@target_user)
    else
      flash[:alert] = "サポートされていないファイル形式です"
      redirect_to incentives_path
    end
  end
  
  private
  
  def check_incentive_permission
    unless current_user&.bonus_eligible?
      flash[:alert] = "インセンティブ機能をご利用いただけません"
      redirect_to root_path
    end
  end
  
  def set_date_range
    if params[:target_month].present?
      begin
        # YYYY-MM形式の月指定を受け取る
        @target_month = params[:target_month]
        @target_date = Date.strptime(@target_month, "%Y-%m")
      rescue ArgumentError
        flash[:alert] = "月の指定に問題があります。正しい月を選択してください。"
        @target_date = Date.current
        @target_month = @target_date.strftime("%Y-%m")
      end
    elsif params[:target_date].present?
      # 後方互換性のため、target_dateも受け付ける
      begin
        @target_date = Date.parse(params[:target_date])
        @target_month = @target_date.strftime("%Y-%m")
      rescue ArgumentError
        flash[:alert] = "日付の指定に問題があります。正しい日付を選択してください。"
        @target_date = Date.current
        @target_month = @target_date.strftime("%Y-%m")
      end
    else
      @target_date = Date.current
      @target_month = @target_date.strftime("%Y-%m")
    end
    
    # 月全体の期間を設定（過去月の場合は月末まで、当月の場合は今日まで）
    @start_date = @target_date.beginning_of_month
    if @target_date.strftime("%Y-%m") == Date.current.strftime("%Y-%m")
      # 当月の場合は今日まで
      @end_date = Date.current
    else
      # 過去月の場合は月末まで
      @end_date = @target_date.end_of_month
    end
    
    @month_str = @target_month
  end
  
  def can_access_user?(user)
    # 自分自身または自分の下位ユーザーかチェック
    return true if user == current_user
    
    # 下位ユーザーかチェック（再帰的に確認）
    current_user.all_descendants.include?(user)
  end
  
  def calculate_incentive_summary
    calculate_incentive_summary_for_user(current_user)
  end

  def calculate_incentive_summary_for_user(user)
    # 月ベースでのインセンティブサマリー計算
    # 既存のmonthly_incentive_with_detailsメソッドを活用
    incentive_data = user.monthly_incentive_with_details(@month_str)
    
    {
      total_incentive: incentive_data[:total] || 0,
      own_sales_incentive: incentive_data.dig(:details, :own_sales) || 0,
      descendant_incentive: incentive_data.dig(:details, :descendant_sales) || 0,

      direct_referrals_count: user.referrals.count,
      purchase_count: incentive_data.dig(:details, :purchase_count) || 0
    }
  end
  
  def calculate_detailed_incentives(user)
    # 新しいIncentiveCalculationServiceを使用
    service = IncentiveCalculationService.new(user, @start_date, @end_date)
    service.calculate_detailed_incentives
  end
  
  def calculate_hierarchy_sales(user)
    # 新しいIncentiveCalculationServiceを使用
    service = IncentiveCalculationService.new(user, @start_date, @end_date)
    hierarchy_data = service.calculate_hierarchy_sales
    
    # デバッグ用ログ
    Rails.logger.debug "=== Hierarchy Data Debug ==="
    hierarchy_data.each do |referral_id, data|
      Rails.logger.debug "Referral ID: #{referral_id}"
      Rails.logger.debug "User Name: #{data[:user].name}"
      Rails.logger.debug "Display Name: #{data[:user_name]}"
      Rails.logger.debug "Level: #{data[:level]}"
      Rails.logger.debug "---"
    end
    
    hierarchy_data
  end
  
  def export_csv(user)
    # CSV エクスポート処理
    # 詳細な実装は後のタスクで行う
    flash[:notice] = "CSV エクスポート機能は実装予定です"
    redirect_to incentives_path
  end
  
  def export_pdf(user)
    # PDF エクスポート処理
    # 詳細な実装は後のタスクで行う
    flash[:notice] = "PDF エクスポート機能は実装予定です"
    redirect_to incentives_path
  end
end