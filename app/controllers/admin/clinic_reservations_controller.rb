class Admin::ClinicReservationsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin
  before_action :set_clinic_reservation, only: [:show, :edit, :update, :destroy]

  def index
    @clinic_reservations = ClinicReservation.includes(:user, :purchase)
                                           .order(created_at: :desc)
    
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
    
    # 統計情報
    @stats = {
      total: ClinicReservation.count,
      pending: ClinicReservation.where(status: ClinicReservation::PENDING).count,
      confirmed: ClinicReservation.where(status: ClinicReservation::CONFIRMED).count,
      completed: ClinicReservation.where(status: ClinicReservation::COMPLETED).count,
      cancelled: ClinicReservation.where(status: ClinicReservation::CANCELLED).count
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

  def complete
    @clinic_reservation = ClinicReservation.find(params[:id])
    @clinic_reservation.update!(status: ClinicReservation::COMPLETED)
    redirect_to admin_clinic_reservation_path(@clinic_reservation), 
                notice: '施術完了にしました。'
  end

  def cancel
    @clinic_reservation = ClinicReservation.find(params[:id])
    @clinic_reservation.update!(status: ClinicReservation::CANCELLED)
    redirect_to admin_clinic_reservation_path(@clinic_reservation), 
                notice: '予約をキャンセルしました。'
  end

  private

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
