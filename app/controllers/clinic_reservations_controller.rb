class ClinicReservationsController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_reservation_permission, only: [:new, :create]
  before_action :set_purchase, only: [:new, :create]
  before_action :set_clinic_reservation, only: [:show, :edit, :update, :destroy]

  def index
    # まだ予約していない購入（クリニック配送があり、statusがpaidで、clinic_reservationがなく、緊急予約依頼もしていない）
    @unreserved_purchases = current_user.purchases
                                       .joins(:delivery_informations)
                                       .where(delivery_informations: { delivery_type: ['clinic', 'multiple'] })
                                       .where(status: 'paid')
                                       .where(emergency_reservation_requested: false)
                                       .left_joins(:clinic_reservation)
                                       .where(clinic_reservations: { id: nil })
                                       .includes(:purchase_items, :delivery_informations)
                                       .distinct
    
    # 過去の予約一覧
    @clinic_reservations = current_user.clinic_reservations.includes(:purchase).order(created_at: :desc)
    
    # 緊急予約依頼済みだがまだクリニック予約が作成されていない購入
    @emergency_pending_purchases = current_user.purchases
                                              .joins(:delivery_informations)
                                              .where(delivery_informations: { delivery_type: ['clinic', 'multiple'] })
                                              .where(status: 'paid')
                                              .where(emergency_reservation_requested: true)
                                              .left_joins(:clinic_reservation)
                                              .where(clinic_reservations: { id: nil })
                                              .includes(:purchase_items, :delivery_informations)
                                              .distinct
  end

  def show
  end

  def new
    # 緊急予約依頼済みの場合はクリニック予約一覧にリダイレクト
    if @purchase.emergency_reservation_requested?
      redirect_to clinic_reservations_path, notice: '緊急予約を依頼済みです。事務局からの連絡をお待ちください。'
      return
    end
    
    @clinic_reservation = @purchase.build_clinic_reservation
    
    # パラメータでclinic_idが指定されている場合はそれを使用
    if params[:clinic_id]
      @clinic_reservation.clinic_id = params[:clinic_id]
    else
      # 購入の配送情報からクリニックを自動設定
      delivery_info = @purchase.delivery_informations.where(delivery_type: ['clinic', 'multiple']).first
      if delivery_info&.clinic_id
        # 新しいClinicモデルのIDを直接使用
        clinic = Clinic.find_by(id: delivery_info.clinic_id)
        if clinic
          @clinic_reservation.clinic_id = clinic.id
        else
          # 古いuser_idベースのclinic_idの場合（互換性のため）
          clinic_user = User.find_by(id: delivery_info.clinic_id)
          if clinic_user&.clinic
            @clinic_reservation.clinic_id = clinic_user.clinic.id
          end
        end
      end
    end
    
    # クリニック情報を取得（営業時間・休憩時間・休診日表示用）
    if @clinic_reservation.clinic_id.present?
      @clinic = Clinic.includes(:clinic_business_hours, :clinic_break_times, :clinic_holidays)
                     .find_by(id: @clinic_reservation.clinic_id)
    end
    
    # 祝日データを取得（JavaScript用）
    require 'holiday_jp'
    current_year = Date.current.year
    next_year = current_year + 1
    @holidays = []
    
    # 今年と来年の祝日を取得
    [current_year, next_year].each do |year|
      year_holidays = HolidayJp.between(Date.new(year, 1, 1), Date.new(year, 12, 31))
      @holidays.concat(year_holidays.map { |h| h.date.strftime('%Y-%m-%d') })
    end
  end

  def create
    Rails.logger.debug "=== CLINIC RESERVATION CREATE DEBUG ==="
    Rails.logger.debug "Raw params: #{params[:clinic_reservation]}"
    Rails.logger.debug "Processed params: #{clinic_reservation_params}"
    Rails.logger.debug "============================================"
    
    @clinic_reservation = @purchase.build_clinic_reservation(clinic_reservation_params)
    @clinic_reservation.user = current_user
    @clinic_reservation.status = ClinicReservation::PENDING

    # 新しいClinicモデルとの関連を設定（要件1.4, 6.5）
    if @clinic_reservation.clinic_id.present?
      clinic = Clinic.find_by(id: @clinic_reservation.clinic_id)
      if clinic.nil?
        # clinic_idがusers.idの場合（既存データとの互換性）
        clinic_user = User.find_by(id: @clinic_reservation.clinic_id)
        if clinic_user&.clinic
          @clinic_reservation.clinic = clinic_user.clinic
        end
      end
    end

    Rails.logger.debug "Treatment methods: #{@clinic_reservation.treatment_methods}"
    Rails.logger.debug "Has stem cell treatment?: #{@clinic_reservation.has_stem_cell_treatment?}"
    Rails.logger.debug "Associated clinic: #{@clinic_reservation.clinic&.name}"

    # 予約可能枠の検証（要件1.5）
    if validate_reservation_slots
      if @clinic_reservation.save
        redirect_to @clinic_reservation, notice: 'クリニック予約が正常に作成されました。'
      else
        Rails.logger.debug "Validation errors: #{@clinic_reservation.errors.full_messages}"
        render :new, status: :unprocessable_entity
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @clinic_reservation.update(clinic_reservation_params)
      redirect_to @clinic_reservation, notice: 'クリニック予約が正常に更新されました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @clinic_reservation.destroy
    redirect_to clinic_reservations_url, notice: 'クリニック予約が削除されました。'
  end

  private

  def validate_reservation_slots
    # 動的時間選択との連携による予約可能枠検証（要件1.5）
    return true unless @clinic_reservation.clinic.present?
    
    availability_service = Clinic::AvailabilityService.new(@clinic_reservation.clinic)
    
    # 各希望日時が予約可能かチェック
    [
      [@clinic_reservation.preferred_date_1, @clinic_reservation.preferred_time_1],
      [@clinic_reservation.preferred_date_2, @clinic_reservation.preferred_time_2],
      [@clinic_reservation.preferred_date_3, @clinic_reservation.preferred_time_3]
    ].each_with_index do |(date, time), index|
      next if date.blank? || time.blank?
      
      begin
        parsed_date = Date.parse(date.to_s)
        available_slots = availability_service.available_slots(parsed_date)
        
        unless available_slots.include?(time)
          @clinic_reservation.errors.add(:base, "第#{index + 1}希望の時間帯（#{time}）は予約できません。")
          return false
        end
      rescue Date::Error
        @clinic_reservation.errors.add(:base, "第#{index + 1}希望の日付が無効です。")
        return false
      end
    end
    
    true
  end

  def verify_reservation_permission
    # 管理者は常に予約可能
    return true if current_user.admin?
    
    # 購入履歴による予約権限チェック（要件1.1）
    unless current_user.has_valid_purchase_for_reservation?
      redirect_to clinic_reservations_path, 
                  alert: '予約を行うには、骨髄幹細胞培養上清液の購入が必要です。'
      return false
    end
    
    true
  end

  def set_purchase
    @purchase = current_user.purchases.find(params[:purchase_id])
  end

  def set_clinic_reservation
    @clinic_reservation = current_user.clinic_reservations.find(params[:id])
  end

  def clinic_reservation_params
    # treatment_methodを単一の値として受け取り、JSONの配列として保存
    permitted_params = params.require(:clinic_reservation).permit(
      :clinic_id, :preferred_date_1, :preferred_time_1, 
      :preferred_date_2, :preferred_time_2, :preferred_date_3, :preferred_time_3,
      :disease_name, :current_treatment, :current_condition, :questions,
      :treatment_method
    )
    
    # 単一のtreatment_methodを配列に変換してtreatment_methodsとして保存
    if permitted_params[:treatment_method].present?
      permitted_params[:treatment_methods] = [permitted_params[:treatment_method]]
      permitted_params.delete(:treatment_method)
    end
    
    # clinic_idの処理（既存システムとの互換性確保）（要件6.5）
    if permitted_params[:clinic_id].present?
      clinic_id = permitted_params[:clinic_id].to_i
      
      # 新しいClinicモデルのIDかチェック
      clinic = Clinic.find_by(id: clinic_id)
      if clinic.nil?
        # 既存のuser_idの場合、対応するClinicを探す
        clinic_user = User.find_by(id: clinic_id)
        if clinic_user&.clinic
          permitted_params[:clinic_id] = clinic_user.clinic.id
        end
      end
    end
    
    permitted_params
  end
end
