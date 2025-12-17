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
    
    # 入金確認待ちの購入請求書件数を取得（status = 2: PAYMENT_CONFIRMATION_REQUEST）
    @payment_confirmation_count = PurchaseInvoice.where(status: PurchaseInvoice::PAYMENT_CONFIRMATION_REQUEST).count
    
    # WOTTレベル昇格申請の承認待ち件数を取得
    @wott_upgrade_requests_count = WottLevelUpgradeRequest.pending.count
    
    # 領収書発行依頼件数を取得（status = 4: RECEIPT_REQUESTED）
    @receipt_requests_count = PurchaseInvoice.where(status: PurchaseInvoice::RECEIPT_REQUESTED).count
    
    # 未回答のお問合せ件数を取得
    @unanswered_inquiries_count = Inquiry.left_joins(:answers).where(answers: { id: nil }).count
    
    # 緊急予約依頼件数を取得（未回答の緊急予約依頼のみ）
    @emergency_reservation_count = Purchase.where(emergency_reservation_requested: true, emergency_reservation_responded_at: nil).count
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
