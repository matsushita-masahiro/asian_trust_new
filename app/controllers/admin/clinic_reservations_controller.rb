class Admin::ClinicReservationsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin
  before_action :set_clinic_reservation, only: [:show, :edit, :update, :destroy]

  def index
    @clinic_reservations = ClinicReservation.includes(:user, :purchase, :clinic)
                                           .order(created_at: :desc)
    
    # 緊急予約フィルタリング
    if params[:emergency] == 'true'
      @clinic_reservations = @clinic_reservations.joins(:purchase)
                                                 .where(purchases: { emergency_reservation_requested: true })
    end
    
    # ステータスでフィルタリング
    if params[:status].present?
      @clinic_reservations = @clinic_reservations.where(status: params[:status])
    end
    
    # 検索機能
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @clinic_reservations = @clinic_reservations.joins(:user)
                                                 .where("users.name ILIKE ? OR users.email ILIKE ?", 
                                                        search_term, search_term)
    end
    
    @clinic_reservations = @clinic_reservations.page(params[:page]).per(20)
    
    # 緊急予約依頼（未回答）- 「全てのステータス」または「申込中」で表示
    if params[:status].blank? || params[:status].to_i == ClinicReservation::PENDING
      @emergency_pending_purchases = Purchase.joins(:delivery_informations)
                                            .where(delivery_informations: { delivery_type: ['clinic', 'multiple'] })
                                            .where(emergency_reservation_requested: true)
                                            .where(emergency_reservation_responded_at: nil)
                                            .left_joins(:clinic_reservation)
                                            .where(clinic_reservations: { id: nil })
                                            .includes(:user, :purchase_items, :delivery_informations)
                                            .distinct
    else
      @emergency_pending_purchases = []
    end
    
    # 緊急予約依頼（回答済み）- 「全てのステータス」または「回答済み」で表示
    if params[:status].blank? || params[:status].to_i == ClinicReservation::CONFIRMED
      @emergency_responded_purchases = Purchase.joins(:delivery_informations)
                                              .where(delivery_informations: { delivery_type: ['clinic', 'multiple'] })
                                              .where(emergency_reservation_requested: true)
                                              .where.not(emergency_reservation_responded_at: nil)
                                              .left_joins(:clinic_reservation)
                                              .where(clinic_reservations: { id: nil })
                                              .includes(:user, :purchase_items, :delivery_informations)
                                              .distinct
                                              .order(emergency_reservation_responded_at: :desc)
    else
      @emergency_responded_purchases = []
    end
    
    # 統計情報
    @stats = {
      total: ClinicReservation.count,
      pending: ClinicReservation.where(status: ClinicReservation::PENDING).count,
      confirmed: ClinicReservation.where(status: ClinicReservation::CONFIRMED).count,
      cancelled: ClinicReservation.where(status: ClinicReservation::CANCELLED).count,
      emergency: Purchase.where(emergency_reservation_requested: true).count
    }
  end

  def show
  end

  def edit
  end

  def update
    if @clinic_reservation.update(clinic_reservation_params)
      redirect_to admin_clinic_reservation_path(@clinic_reservation), 
                  notice: 'クリニック予約が正常に更新されました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @clinic_reservation.destroy
    redirect_to admin_clinic_reservations_path, 
                notice: 'クリニック予約が削除されました。'
  end

  # ステータス変更用のアクション
  def confirm
    @clinic_reservation = ClinicReservation.find(params[:id])
    @clinic_reservation.update!(status: ClinicReservation::CONFIRMED)
    redirect_to admin_clinic_reservation_path(@clinic_reservation), 
                notice: '予約を確定しました。'
  end
  
  # 選択した希望日時で予約確定（要件3.4, 3.5）
  def confirm_with_selection
    @clinic_reservation = ClinicReservation.find(params[:id])
    selected_preference = params[:selected_preference].to_i
    
    # 営業時間内であることを検証（要件3.3）
    unless validate_confirmation_time(selected_preference)
      redirect_to admin_clinic_reservation_path(@clinic_reservation), 
                  alert: '選択された日時はクリニックの営業時間外です。'
      return
    end
    
    # 選択された希望番号を保存
    @clinic_reservation.confirmed_preference = selected_preference
    
    # 選択された希望日時を確定日時として保存
    case selected_preference
    when 1
      @clinic_reservation.confirmed_date = @clinic_reservation.preferred_date_1
      @clinic_reservation.confirmed_time = @clinic_reservation.preferred_time_1
    when 2
      @clinic_reservation.confirmed_date = @clinic_reservation.preferred_date_2
      @clinic_reservation.confirmed_time = @clinic_reservation.preferred_time_2
    when 3
      @clinic_reservation.confirmed_date = @clinic_reservation.preferred_date_3
      @clinic_reservation.confirmed_time = @clinic_reservation.preferred_time_3
    end
    
    # ステータスを確定に変更
    @clinic_reservation.status = ClinicReservation::CONFIRMED
    
    if @clinic_reservation.save
      # 確定通知の送信（要件3.5）
      send_confirmation_notification(@clinic_reservation)
      
      preference_label = case selected_preference
                        when 1 then "第1希望"
                        when 2 then "第2希望"
                        when 3 then "第3希望"
                        end
      redirect_to admin_clinic_reservation_path(@clinic_reservation), 
                  notice: "予約を確定しました（#{preference_label}）。確定日時: #{@clinic_reservation.confirmed_date&.strftime('%Y年%m月%d日')} #{@clinic_reservation.confirmed_time}"
    else
      redirect_to admin_clinic_reservation_path(@clinic_reservation), 
                  alert: '予約の確定に失敗しました。'
    end
  end



  def cancel
    @clinic_reservation = ClinicReservation.find(params[:id])
    @clinic_reservation.update!(status: ClinicReservation::CANCELLED)
    redirect_to admin_clinic_reservation_path(@clinic_reservation), 
                notice: '予約をキャンセルしました。'
  end

  def resolve_emergency
    @clinic_reservation = ClinicReservation.find(params[:id])
    purchase = @clinic_reservation.purchase
    
    if purchase&.update(emergency_reservation_requested: false)
      # 解決済み通知をユーザーに送信
      send_emergency_resolution_notification(purchase)
      
      redirect_to admin_clinic_reservation_path(@clinic_reservation), 
                  notice: '緊急予約依頼を解決済みにしました。'
    else
      redirect_to admin_clinic_reservation_path(@clinic_reservation), 
                  alert: '更新に失敗しました。'
    end
  end

  def respond_to_emergency
    @purchase = Purchase.find(params[:id])
    
    if @purchase.update(emergency_response_params.merge(
      emergency_reservation_responded_at: Time.current,
      emergency_reservation_responded_by: current_user.id
    ))
      # ユーザーに回答通知を送信
      send_emergency_response_notification(@purchase)
      
      redirect_to admin_clinic_reservations_path, 
                  notice: '緊急予約に回答しました。ユーザーに通知を送信しました。'
    else
      redirect_to admin_clinic_reservations_path, 
                  alert: '回答の保存に失敗しました。'
    end
  end

  private

  def validate_confirmation_time(selected_preference)
    # 営業時間内であることを検証（要件3.3）
    return true unless @clinic_reservation.clinic.present?
    
    date, time = case selected_preference
                 when 1
                   [@clinic_reservation.preferred_date_1, @clinic_reservation.preferred_time_1]
                 when 2
                   [@clinic_reservation.preferred_date_2, @clinic_reservation.preferred_time_2]
                 when 3
                   [@clinic_reservation.preferred_date_3, @clinic_reservation.preferred_time_3]
                 end
    
    return false if date.blank? || time.blank?
    
    begin
      parsed_date = Date.parse(date.to_s)
      availability_service = Clinic::AvailabilityService.new(@clinic_reservation.clinic)
      available_slots = availability_service.available_slots(parsed_date)
      
      available_slots.include?(time)
    rescue Date::Error
      false
    end
  end
  
  def send_confirmation_notification(clinic_reservation)
    # 確定通知の送信（要件3.5）
    begin
      # 通知レコードの作成
      notification = Notification.create!(
        user: clinic_reservation.user,
        title: 'クリニック予約が確定しました',
        message: build_confirmation_message(clinic_reservation),
        notification_type: Notification::CLINIC_RESERVATION_CONFIRMED,
        link_url: clinic_reservations_path
      )
      
      # メール送信
      ClinicReservationMailer.reservation_confirmed(clinic_reservation).deliver_now
      
      Rails.logger.info "Confirmation notification and email sent to user #{clinic_reservation.user.id} for reservation #{clinic_reservation.id}"
    rescue => e
      Rails.logger.error "Failed to send confirmation notification: #{e.message}"
    end
  end
  
  def build_confirmation_message(clinic_reservation)
    clinic_name = clinic_reservation.clinic&.name || 'クリニック'
    confirmed_date = clinic_reservation.confirmed_date&.strftime('%Y年%m月%d日')
    confirmed_time = clinic_reservation.confirmed_time
    
    "#{clinic_name}での予約が確定しました。\n" \
    "確定日時: #{confirmed_date} #{confirmed_time}\n" \
    "予約詳細は予約一覧からご確認ください。"
  end

  def send_emergency_resolution_notification(purchase)
    begin
      Notification.create!(
        user: purchase.user,
        title: '緊急予約依頼について',
        message: "緊急予約依頼（購入ID: #{purchase.id}）について、事務局で確認いたしました。詳細については別途ご連絡いたします。",
        notification_type: Notification::CLINIC_RESERVATION_CONFIRMED,
        link_url: purchase_path(purchase)
      )
      
      Rails.logger.info "Emergency reservation resolution notification sent to user #{purchase.user.id} for purchase #{purchase.id}"
    rescue => e
      Rails.logger.error "Failed to send emergency reservation resolution notification: #{e.message}"
    end
  end

  def send_emergency_response_notification(purchase)
    begin
      Notification.create!(
        user: purchase.user,
        title: '緊急予約の回答が届きました',
        message: "緊急予約依頼（購入ID: #{purchase.id}）について、事務局から回答が届きました。クリニック予約一覧でご確認ください。",
        notification_type: Notification::CLINIC_RESERVATION_CONFIRMED,
        link_url: clinic_reservations_path
      )
      
      # メール送信
      ClinicReservationMailer.emergency_response(purchase).deliver_now
      
      Rails.logger.info "Emergency reservation response notification and email sent to user #{purchase.user.id} for purchase #{purchase.id}"
    rescue => e
      Rails.logger.error "Failed to send emergency reservation response notification: #{e.message}"
    end
  end

  def emergency_response_params
    params.require(:purchase).permit(:emergency_reservation_response)
  end

  def set_clinic_reservation
    @clinic_reservation = ClinicReservation.find(params[:id])
  end

  def clinic_reservation_params
    params.require(:clinic_reservation).permit(
      :status, :preferred_date_1, :preferred_time_1, 
      :preferred_date_2, :preferred_time_2, :preferred_date_3, :preferred_time_3,
      :disease_name, :current_treatment, :current_condition, :questions,
      treatment_methods: []
    )
  end

  def ensure_admin
    redirect_to root_path unless current_user&.admin?
  end
end
