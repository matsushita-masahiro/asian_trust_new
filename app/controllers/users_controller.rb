class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_selected_month_range
  # 現在のユーザーのマイページ
  def mysales
    @user = current_user
  end

  # 下位ユーザーの詳細（再帰的に遷移可能）
  def show
    @user = User.find(params[:id])

    # アクセス権限チェック
    unless can_access_user?(@user)
      redirect_to mypage_users_path, alert: "権限がありません。"
      return
    end
    
    # 自分自身のページを見ている場合、通知を作成
    if @user == current_user
      # クリニック予約が必要な購入の通知を作成
      pending_purchases = current_user.purchases
                                      .joins(:purchase_invoice, :delivery_informations)
                                      .where(status: 'paid')
                                      .where(purchase_invoices: { status: 3 })
                                      .where(delivery_informations: { delivery_type: ['clinic', 'multiple'] })
                                      .where.missing(:clinic_reservation)
                                      .distinct
      
      pending_purchases.each do |purchase|
        # 既に通知が存在しない場合のみ作成
        unless current_user.notifications.exists?(
          notification_type: Notification::CLINIC_RESERVATION_REQUIRED,
          link_url: new_purchase_clinic_reservation_path(purchase)
        )
          current_user.notifications.create!(
            notification_type: Notification::CLINIC_RESERVATION_REQUIRED,
            title: 'クリニック予約が必要です',
            message: "購入ID: #{purchase.id} のクリニック予約をお願いします。",
            link_url: new_purchase_clinic_reservation_path(purchase)
          )
        end
      end
      
      # クリニック予約確定済みの通知を作成
      confirmed_reservations = current_user.clinic_reservations.where(status: 1)
      confirmed_reservations.each do |reservation|
        # 既に通知が存在しない場合のみ作成
        unless current_user.notifications.exists?(
          notification_type: Notification::CLINIC_RESERVATION_CONFIRMED,
          link_url: clinic_reservations_path
        )
          current_user.notifications.create!(
            notification_type: Notification::CLINIC_RESERVATION_CONFIRMED,
            title: 'クリニック予約が確定しました',
            message: "予約ID: #{reservation.id} の予約が確定しました。確定日時: #{reservation.confirmed_date&.strftime('%Y年%m月%d日')} #{reservation.confirmed_time}",
            link_url: clinic_reservations_path
          )
        end
      end
    end
  end

  def mypage
    @user = current_user
    
    # 通知を作成（show アクションと同じロジック）
    # クリニック予約が必要な購入の通知を作成
    pending_purchases = current_user.purchases
                                    .joins(:purchase_invoice, :delivery_informations)
                                    .where(status: 'paid')
                                    .where(purchase_invoices: { status: 3 })
                                    .where(delivery_informations: { delivery_type: ['clinic', 'multiple'] })
                                    .where.missing(:clinic_reservation)
                                    .distinct
    
    pending_purchases.each do |purchase|
      unless current_user.notifications.exists?(
        notification_type: Notification::CLINIC_RESERVATION_REQUIRED,
        link_url: new_purchase_clinic_reservation_path(purchase)
      )
        current_user.notifications.create!(
          notification_type: Notification::CLINIC_RESERVATION_REQUIRED,
          title: 'クリニック予約が必要です',
          message: "購入ID: #{purchase.id} のクリニック予約をお願いします。",
          link_url: new_purchase_clinic_reservation_path(purchase)
        )
      end
    end
    
    # クリニック予約確定済みの通知を作成
    confirmed_reservations = current_user.clinic_reservations.where(status: 1)
    confirmed_reservations.each do |reservation|
      unless current_user.notifications.exists?(
        notification_type: Notification::CLINIC_RESERVATION_CONFIRMED,
        link_url: clinic_reservations_path
      )
        current_user.notifications.create!(
          notification_type: Notification::CLINIC_RESERVATION_CONFIRMED,
          title: 'クリニック予約が確定しました',
          message: "予約ID: #{reservation.id} の予約が確定しました。確定日時: #{reservation.confirmed_date&.strftime('%Y年%m月%d日')} #{reservation.confirmed_time}",
          link_url: clinic_reservations_path
        )
      end
    end
    
    render :show
  end

  # メールアドレス更新
  def update
    @user = User.find(params[:id])
    
    # 自分自身のみ更新可能
    unless @user == current_user
      redirect_to user_path(@user), alert: "権限がありません。"
      return
    end
    
    if @user.update(user_params)
      # 更新されたフィールドに応じてメッセージを変更
      updated_fields = []
      updated_fields << "メールアドレス" if user_params[:email].present?
      updated_fields << "電話番号" if user_params[:phone].present?
      
      field_name = updated_fields.join("・")
      redirect_to user_path(@user), notice: "#{field_name}を更新しました。"
    else
      redirect_to user_path(@user), alert: "更新に失敗しました。#{@user.errors.full_messages.join(', ')}"
    end
  end

  # 販売履歴・購入履歴表示
  def purchases
    @user = User.find(params[:id])

    unless can_access_user?(@user)
      redirect_to mypage_users_path, alert: "権限がありません。"
      return
    end

    @selected_month = params[:month] || Time.current.strftime('%Y-%m')
    
    begin
      # URLパラメータで表示モードを判定
      # ?view=own_purchases が指定された場合は自分の購入履歴を表示
      if params[:view] == 'own_purchases'
        # 自分自身の購入履歴を表示（user_idが自分のユーザーIDと一致するもの）
        @purchases = Purchase.includes({ purchase_items: :product }, :user)
                            .where(user_id: @user.id)
                            .in_month_tokyo(@selected_month)
                            .order(purchased_at: :desc)
        @is_customer_view = true
        @is_own_purchases = true
      elsif @user.level.value == 8
        # お客様の場合：自分が購入者として記録された購入履歴を表示
        @purchases = Purchase.includes({ purchase_items: :product }, :user)
                            .where(user_id: @user.id)
                            .in_month_tokyo(@selected_month)
                            .order(purchased_at: :desc)
        @is_customer_view = true
        @is_own_purchases = false
      else
        # 指定ユーザーの購入履歴を取得
        @purchases = Purchase.includes({ purchase_items: :product }, :user)
                            .where(user_id: @user.id)
                            .in_month_tokyo(@selected_month)
                            .order(purchased_at: :desc)
        @is_customer_view = false
        @is_own_purchases = false
      end
    rescue => e
      Rails.logger.error "Error loading purchases: #{e.message}"
      @purchases = Purchase.none
      flash.now[:alert] = "購入履歴の読み込み中にエラーが発生しました。"
    end
    
    # 統計情報
    @total_amount = @purchases.sum(&:total_price)
    @total_count = @purchases.count
    
    # 月選択用のオプション（過去12ヶ月分）
    @month_options = generate_month_options
    
    # 月名（日本語）
    @selected_month_name = Time.zone.parse("#{@selected_month}-01").strftime('%Y年%m月')
  end
  
  private

    # ユーザーへのアクセス権限をチェック
    def can_access_user?(user)
      # 自分自身の場合はアクセス可能
      return true if user == current_user
      
      # 自分の下位ユーザーの場合はアクセス可能
      return true if current_user.descendants.include?(user)
      
      # 自分より上位のユーザーへのアクセスは禁止
      # （ただし、自分の祖先ユーザーで、かつ現在表示中のユーザーの上位にあたる場合は許可）
      if current_user.ancestors.include?(user)
        # 現在表示中のユーザーが自分の下位で、かつアクセス対象が現在ユーザーの上位の場合のみ許可
        current_displayed_user = User.find(params[:id]) rescue current_user
        return current_displayed_user.ancestors.include?(user) && current_user.descendants.include?(current_displayed_user)
      end
      
      false
    end

    def set_selected_month_range
      selected_month = params[:month].presence || Date.today.strftime("%Y-%m")
      @selected_month = selected_month
      @selected_month_start = Date.strptime(selected_month, "%Y-%m").beginning_of_month
      @selected_month_end   = Date.strptime(selected_month, "%Y-%m").end_of_month
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

    def user_params
      params.require(:user).permit(:email, :phone)
    end
end
