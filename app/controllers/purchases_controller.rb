class PurchasesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_purchase, only: [:show]

  # 自分の購入履歴一覧
  def my_history
    # 月選択（デフォルトは今月）
    @selected_month = params[:month].presence || Date.current.strftime('%Y-%m')
    @selected_month_start = Date.strptime(@selected_month, '%Y-%m').beginning_of_month
    @selected_month_end = Date.strptime(@selected_month, '%Y-%m').end_of_month

    # 自分の購入履歴を取得
    @purchases = current_user.purchases
                            .includes({ purchase_items: :product }, :shipping_fees, :purchase_invoice)
                            .where(purchased_at: @selected_month_start..@selected_month_end)
                            .order(purchased_at: :desc)

    # 統計情報（送料・事務手数料込み）
    @total_amount = @purchases.sum do |purchase|
      purchase.total_price + 
      purchase.total_shipping_fees + 
      (purchase.purchase_invoice&.admin_fee || 0)
    end
    @total_count = @purchases.count
    @total_items = @purchases.joins(:purchase_items).sum('purchase_items.quantity')

    # 月選択用のオプション（過去12ヶ月分）
    @month_options = generate_month_options

    # 月名（日本語）
    @selected_month_name = Time.zone.parse("#{@selected_month}-01").strftime('%Y年%m月')
  end

  # 購入履歴詳細
  def show
    # 自分の購入履歴のみ表示可能
    unless @purchase.user == current_user
      redirect_to purchases_my_history_path, alert: '権限がありません。'
      return
    end

    # 購入アイテムの詳細情報
    @purchase_items = @purchase.purchase_items.includes(:product)
    
    # 合計金額（商品代金 + 送料 + 消費税 + 事務手数料）
    @items_total = @purchase.total_price
    @shipping_fees_total = @purchase.total_shipping_fees
    @tax_amount = @purchase.tax_amount
    @admin_fee = @purchase.purchase_invoice&.admin_fee || 0
    @total_amount = @purchase.grand_total
    
    @total_items = @purchase_items.sum(:quantity)
    
    # 送料の詳細
    @shipping_fee_details = @purchase.shipping_fee_details
  end

  private

  def set_purchase
    @purchase = Purchase.includes(:purchase_invoice, :shipping_fees).find(params[:id])
  end

  def generate_month_options
    options = []
    12.times do |i|
      date = Time.current.beginning_of_month - i.months
      value = date.strftime('%Y-%m')
      label = date.strftime('%Y年%m月')
      options << [label, value]
    end
    options
  end
end