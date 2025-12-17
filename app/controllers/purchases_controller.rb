class PurchasesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_purchase, only: [:show, :request_emergency_reservation]

  # 自分の購入履歴一覧
  def my_history
    # 月選択（デフォルトは今月）
    @selected_month = params[:month].presence || Date.current.strftime('%Y-%m')
    @selected_month_start = Date.strptime(@selected_month, '%Y-%m').beginning_of_month.beginning_of_day
    @selected_month_end = Date.strptime(@selected_month, '%Y-%m').end_of_month.end_of_day

    # 自分の購入履歴を取得
    @purchases = current_user.purchases
                            .includes({ purchase_items: :product }, :shipping_fees, :purchase_invoice)
                            .where(purchased_at: @selected_month_start..@selected_month_end)
                            .order(purchased_at: :desc)

    # 統計情報（税込み金額）
    @total_amount = @purchases.sum do |purchase|
      # purchase_invoiceがある場合は税込み金額を使用
      if purchase.purchase_invoice&.total_with_tax.present? && purchase.purchase_invoice.total_with_tax > 0
        purchase.purchase_invoice.total_with_tax
      else
        # 従来の計算方法（税込み）
        product_amount = purchase.total_price
        shipping_fee = purchase.total_shipping_fees
        admin_fee = purchase.purchase_invoice&.admin_fee || 0
        subtotal_before_tax = product_amount + shipping_fee + admin_fee
        tax_amount = (subtotal_before_tax * 0.1).round  # 消費税10%
        subtotal_before_tax + tax_amount
      end
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

  def request_emergency_reservation
    # 自分の購入のみ緊急予約依頼可能
    unless @purchase.user == current_user
      redirect_to new_purchase_clinic_reservation_path(@purchase), alert: '権限がありません。'
      return
    end

    # 既に緊急予約依頼済みの場合
    if @purchase.emergency_reservation_requested?
      redirect_to new_purchase_clinic_reservation_path(@purchase), alert: '既に緊急予約を依頼済みです。'
      return
    end

    # 緊急予約依頼を保存
    if @purchase.update(emergency_reservation_params.merge(emergency_reservation_requested: true))
      # 事務局に通知を送信
      send_emergency_reservation_notification(@purchase)
      
      redirect_to clinic_reservations_path, notice: '緊急予約を依頼しました。事務局が確認後、ご連絡いたします。'
    else
      redirect_to new_purchase_clinic_reservation_path(@purchase), alert: '緊急予約の依頼に失敗しました。'
    end
  end

  private

  def send_emergency_reservation_notification(purchase)
    # 事務局ユーザー（level.value = 0）に通知を送信
    admin_users = User.joins(:level).where(levels: { value: 0 })
    
    admin_users.each do |admin_user|
      begin
        notification = Notification.create!(
          user: admin_user,
          title: '緊急予約依頼がありました',
          message: build_emergency_reservation_message(purchase),
          notification_type: Notification::EMERGENCY_RESERVATION_REQUESTED,
          link_url: admin_purchase_path(purchase)
        )
        
        Rails.logger.info "Emergency reservation notification sent to admin #{admin_user.id} for purchase #{purchase.id}"
      rescue => e
        Rails.logger.error "Failed to send emergency reservation notification to admin #{admin_user.id}: #{e.message}"
      end
    end
  end
  
  def build_emergency_reservation_message(purchase)
    "ユーザー「#{purchase.user.name}」から緊急予約の依頼がありました。\n\n" \
    "購入ID: #{purchase.id}\n" \
    "依頼内容: #{purchase.emergency_reservation_message}\n\n" \
    "管理画面で詳細をご確認ください。"
  end
  
  def emergency_reservation_params
    params.require(:purchase).permit(:emergency_reservation_message)
  end

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