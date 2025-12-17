class AvailableTimesController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_reservation_permission
  
  def index
    clinic = Clinic.find(params[:clinic_id])
    date = Date.parse(params[:date])
    
    service = Clinic::AvailabilityService.new(clinic)
    available_slots = service.available_slots(date)
    
    render json: available_slots
  rescue Date::Error
    render json: { error: "Invalid date format" }, status: :bad_request
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Clinic not found" }, status: :not_found
  rescue => e
    Rails.logger.error "AvailableTimesController error: #{e.message}"
    render json: { error: "Internal server error" }, status: :internal_server_error
  end
  
  private
  
  def verify_reservation_permission
    # 購入履歴による予約権限チェック（要件1.1）
    unless current_user.has_valid_purchase_for_reservation?
      render json: { error: '予約を行うには、骨髄幹細胞培養上清液の購入が必要です。' }, 
             status: :forbidden
      return false
    end
    
    # 管理者は常に予約可能
    return true if current_user.admin?
    
    true
  end
end