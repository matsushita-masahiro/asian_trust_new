class Admin::DashboardController < Admin::BaseController
  def index
    # システム状態チェック
    @system_health = SystemHealthChecker.cached_status
    
    # 今月の総売上を取得
    @monthly_total_sales = get_monthly_total_sales
    
    # 未入金注文件数を取得
    @pending_payments_count = Purchase.built.count
    
    # アドバイザー認定前ユーザー数を取得
    @advisor_pre_count = User.joins(:level).where(levels: { name: 'アドバイザー認定前' }).count
  end

  private

  def get_monthly_total_sales
    # 今月の購入データを取得してunit_priceベースで合計を計算
    current_month_start = Date.current.beginning_of_month
    current_month_end = Date.current.end_of_month
    
    purchases = Purchase.where(purchased_at: current_month_start..current_month_end)
    total_sales = purchases.sum { |purchase| 
      purchase.purchase_items.sum { |item| item.quantity * item.unit_price } 
    }
    
    Rails.logger.info "今月の総売上: #{total_sales}円"
    total_sales
  end
end
