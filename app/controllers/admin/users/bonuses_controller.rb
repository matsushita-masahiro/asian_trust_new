class Admin::Users::BonusesController < Admin::BaseController
  before_action :set_user
  before_action :set_selected_month_range

  def index
    begin
      # 基本的にsales/indexと同じ内容だが、管理者向けの詳細情報を追加
      @purchases = @user.purchases.includes(purchase_items: :product)
      
      # 期間でフィルタリング（in_periodメソッドが存在しない場合の対応）
      if @purchases.respond_to?(:in_period)
        @purchases = @purchases.in_period(@selected_month_start, @selected_month_end)
      else
        @purchases = @purchases.where(purchased_at: @selected_month_start..@selected_month_end)
      end
      
      # 自身 + 下位の購入履歴（選択月）
      descendant_ids = @user.descendants.pluck(:id)
      @purchases_with_descendants = Purchase.includes(purchase_items: :product, user: [])
                                            .where(user_id: [@user.id] + descendant_ids)
                                            .where(purchased_at: @selected_month_start..@selected_month_end)
                                            .order(purchased_at: :desc)
                                            .order(purchased_at: :desc)
                                            .order(purchased_at: :desc)
                                            .order(purchased_at: :desc)
                                            .order(purchased_at: :desc)

      # 安全な計算 - purchase_itemsを通じて計算
      @total_sales_amount = @purchases_with_descendants.joins(purchase_items: :product).sum('purchase_items.seller_price * purchase_items.quantity') rescue 0
      
      # ボーナス計算 - WOTTインセンティブを含む正しい計算を使用
      incentive_data = @user.monthly_incentive_with_details(@selected_month)
      @total_bonus = incentive_data[:total] || 0
      
      # 支払済みと未払いのインセンティブを分けて計算
      @paid_bonus = 0
      @unpaid_bonus = 0
      
      @purchases_with_descendants.each do |purchase|
        purchase.purchase_items.each do |item|
          item_bonus = @user.bonus_for_purchase_item(item)
          if purchase.status == 'paid'
            @paid_bonus += item_bonus
          else
            @unpaid_bonus += item_bonus
          end
        end
      end
      
      # 直接紹介者
      @referrals = @user.referrals
      
    rescue => e
      Rails.logger.error "Admin::Users::BonusesController#index error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # エラー時のデフォルト値
      @purchases = Purchase.none
      @purchases_with_descendants = Purchase.none
      @total_sales_amount = 0
      @total_bonus = 0
      @paid_bonus = 0
      @unpaid_bonus = 0
      @referrals = User.none
      
      flash.now[:error] = "データの取得中にエラーが発生しました。"
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_bonuses_path, alert: "ユーザーが見つかりません。"
  end

  def set_selected_month_range
    selected_month = params[:month].presence || Date.current.strftime("%Y-%m")
    @selected_month = selected_month
    
    begin
      @selected_month_start = Date.strptime(selected_month, "%Y-%m").beginning_of_month
      @selected_month_end   = Date.strptime(selected_month, "%Y-%m").end_of_month
    rescue ArgumentError
      # 無効な日付の場合は今月を使用
      @selected_month = Date.current.strftime("%Y-%m")
      @selected_month_start = Date.current.beginning_of_month
      @selected_month_end   = Date.current.end_of_month
    end
  end
end