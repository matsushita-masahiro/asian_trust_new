class Admin::IncentivesController < Admin::BaseController
  before_action :set_date_range
  before_action :set_target_user, only: [:show, :drill_down, :breakdown]
  
  def index
    # 管理者用のインセンティブ一覧画面
    # 全ユーザーのインセンティブサマリーを表示
    @bonus_eligible_users = User.joins(:level)
                               .where(levels: { name: User::BONUS_ELIGIBLE_LEVELS })
                               .includes(:level, :referrals, :purchases)

    @incentive_data = []
    @bonus_eligible_users.each do |user|
      incentive_amount = user.bonus_in_period(@start_date, @end_date)
      
      if incentive_amount > 0
        @incentive_data << {
          user: user,
          incentive_amount: incentive_amount
        }
      end
    end

    # インセンティブ額の降順でソート
    @incentive_data.sort_by! { |data| -data[:incentive_amount] }
  end
  
  def show
    # 特定ユーザーのインセンティブ詳細表示（管理者用）
    @direct_referrals = @target_user.referrals
    @incentive_summary = calculate_incentive_summary_for_user(@target_user)
    @hierarchy_data = calculate_hierarchy_sales(@target_user)
  end
  
  def drill_down
    # 階層ドリルダウン機能（管理者用）
    @direct_referrals = @target_user.referrals
    @incentive_summary = calculate_incentive_summary_for_user(@target_user)
    @hierarchy_data = calculate_hierarchy_sales(@target_user)
    
    render :show
  end
  
  def breakdown
    # インセンティブ明細表示（管理者用）
    @incentive_summary = calculate_incentive_summary_for_user(@target_user)
    
    # IncentiveCalculationServiceを使用して詳細なインセンティブ計算を取得
    service = IncentiveCalculationService.new(@target_user, @start_date, @end_date)
    @detailed_incentives = service.calculate_detailed_incentives
    
    # ユーザーの商品単価情報を取得
    @user_product_prices = get_user_product_prices(@target_user)
  end
  
  private
  
  def set_target_user
    @target_user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_incentives_path, alert: "ユーザーが見つかりません。"
  end
  
  def set_date_range
    if params[:target_month].present?
      begin
        @target_month = params[:target_month]
        @target_date = Date.strptime(@target_month, "%Y-%m")
      rescue ArgumentError
        flash[:alert] = "月の指定に問題があります。正しい月を選択してください。"
        @target_date = Date.current
        @target_month = @target_date.strftime("%Y-%m")
      end
    else
      @target_date = Date.current
      @target_month = @target_date.strftime("%Y-%m")
    end
    
    @start_date = @target_date.beginning_of_month
    if @target_date.strftime("%Y-%m") == Date.current.strftime("%Y-%m")
      @end_date = Date.current
    else
      @end_date = @target_date.end_of_month
    end
    
    @month_str = @target_month
  end
  
  def calculate_incentive_summary_for_user(user)
    incentive_data = user.monthly_incentive_with_details(@month_str)
    
    # 自己購入金額を計算
    own_sales_amount = calculate_own_sales_amount(user)
    
    # デバッグ情報
    Rails.logger.debug "=== Incentive Summary Debug ==="
    Rails.logger.debug "User: #{user.name}"
    Rails.logger.debug "Month: #{@month_str}"
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
    # 指定期間内の自己購入金額を計算（seller_priceを使用）
    user.purchases
        .where(purchased_at: @start_date..@end_date)
        .joins(:purchase_items)
        .sum('purchase_items.seller_price * purchase_items.quantity')
  end
  
  def calculate_hierarchy_sales(user)
    hierarchy_data = {}
    
    user.referrals.each do |referral|
      # 各直下ユーザーのインセンティブ金額を計算（WOTTインセンティブを含む）
      referral_incentive_data = referral.monthly_incentive_with_details(@month_str)
      incentive_amount = referral_incentive_data[:total] || 0
      
      # 売上合計を計算
      sales_total = referral.total_sales_with_descendants(@month_str)
      
      # 子孫がいるかチェック
      has_descendants = referral.referrals.any?
      
      hierarchy_data[referral.id] = {
        user: referral,
        level: referral.level&.name || "未設定",
        sales_total: sales_total,
        incentive_amount: incentive_amount,
        has_descendants: has_descendants
      }
    end
    
    hierarchy_data
  end
  
  def get_user_product_prices(user)
    # アクティブな商品のみを取得
    products = Product.where(deleted_at: nil).order(:id)
    user_level = user.level
    
    products.map do |product|
      if product.respond_to?(:category) && product.category == 'wott' && user.wott_level
        # WOTT商品の場合はWOTTレベルの価格を取得
        product_price = ProductPrice.find_by(product: product, wott_level: user.wott_level)
        price = product_price&.price || product.base_price
      else
        # 通常商品の場合は通常レベルの価格を取得
        product_price = ProductPrice.find_by(product: product, level: user_level)
        price = product_price&.price || product.base_price
      end
      
      {
        product: product,
        price: price
      }
    end
  end
end