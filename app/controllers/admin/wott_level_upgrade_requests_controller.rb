class Admin::WottLevelUpgradeRequestsController < Admin::BaseController
  before_action :set_request, only: [:show, :approve, :reject]

  def index
    @status = params[:status] || 'pending'
    @requests = case @status
                when 'pending'
                  WottLevelUpgradeRequest.pending
                when 'approved'
                  WottLevelUpgradeRequest.approved
                when 'rejected'
                  WottLevelUpgradeRequest.rejected
                else
                  WottLevelUpgradeRequest.all
                end
    @requests = @requests.includes(:user, :current_wott_level, :requested_wott_level, :purchase, :processed_by)
                         .order(created_at: :desc)
                         .page(params[:page]).per(20)
  end

  def show
  end

  def approve
    if @request.approve!(current_user, notes: params[:admin_notes])
      redirect_to admin_wott_level_upgrade_requests_path, notice: 'WOTTレベル昇格申請を承認しました。'
    else
      redirect_to admin_wott_level_upgrade_request_path(@request), alert: '承認処理に失敗しました。'
    end
  end

  def reject
    if @request.reject!(current_user, notes: params[:admin_notes])
      redirect_to admin_wott_level_upgrade_requests_path, notice: 'WOTTレベル昇格申請を却下しました。'
    else
      redirect_to admin_wott_level_upgrade_request_path(@request), alert: '却下処理に失敗しました。'
    end
  end

  private

  def set_request
    @request = WottLevelUpgradeRequest.find(params[:id])
  end
end
