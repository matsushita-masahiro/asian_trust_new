class ClinicReservationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_purchase, only: [:new, :create]
  before_action :set_clinic_reservation, only: [:show, :edit, :update, :destroy]

  def index
    # まだ予約していない購入（クリニック配送があり、statusがpaidで、clinic_reservationがない）
    @unreserved_purchases = current_user.purchases
                                       .joins(:delivery_informations)
                                       .where(delivery_informations: { delivery_type: ['clinic', 'multiple'] })
                                       .where(status: 'paid')
                                       .left_joins(:clinic_reservation)
                                       .where(clinic_reservations: { id: nil })
                                       .includes(:purchase_items, :delivery_informations)
                                       .distinct
    
    # 過去の予約一覧
    @clinic_reservations = current_user.clinic_reservations.includes(:purchase).order(created_at: :desc)
  end

  def show
  end

  def new
    @clinic_reservation = @purchase.build_clinic_reservation
    @clinic_reservation.clinic_id = params[:clinic_id] if params[:clinic_id]
  end

  def create
    Rails.logger.debug "=== CLINIC RESERVATION CREATE DEBUG ==="
    Rails.logger.debug "Raw params: #{params[:clinic_reservation]}"
    Rails.logger.debug "Processed params: #{clinic_reservation_params}"
    Rails.logger.debug "============================================"
    
    @clinic_reservation = @purchase.build_clinic_reservation(clinic_reservation_params)
    @clinic_reservation.user = current_user
    @clinic_reservation.status = ClinicReservation::PENDING

    Rails.logger.debug "Treatment methods: #{@clinic_reservation.treatment_methods}"
    Rails.logger.debug "Has stem cell treatment?: #{@clinic_reservation.has_stem_cell_treatment?}"

    if @clinic_reservation.save
      redirect_to @clinic_reservation, notice: 'クリニック予約が正常に作成されました。'
    else
      Rails.logger.debug "Validation errors: #{@clinic_reservation.errors.full_messages}"
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
    
    permitted_params
  end
end
