class Admin::LevelChangeApplicationsController < Admin::BaseController
  before_action :set_application, only: [:show, :cancel]

  def index
    @applications = LevelChangeApplication.includes(:user, :current_level, :target_level, :applicant)
                                         .recent
                                         .page(params[:page])
                                         .per(20)

    # ステータスフィルタ
    if params[:status].present? && LevelChangeApplication.statuses.key?(params[:status])
      @applications = @applications.where(status: params[:status])
    end

    # ユーザーフィルタ
    if params[:user_id].present?
      @applications = @applications.where(user_id: params[:user_id])
    end

    @status_counts = {
      all: LevelChangeApplication.count,
      pending: LevelChangeApplication.pending.count,
      completed: LevelChangeApplication.completed.count,
      cancelled: LevelChangeApplication.cancelled.count,
      error: LevelChangeApplication.error.count
    }
  end

  def show
    @level_histories = @application.user.user_level_histories
                                        .includes(:level, :previous_level, :changed_by)
                                        .recent
                                        .limit(10)
  end

  def cancel
    unless @application.cancellable?
      redirect_to admin_level_change_applications_path, 
                  alert: 'この申請はキャンセルできません。'
      return
    end

    if @application.cancel!
      Rails.logger.info "Level change application #{@application.id} cancelled by #{current_user.id}"
      
      # キャンセル通知
      LevelChangeErrorNotifier.notify_application_cancelled(@application, current_user)
      
      redirect_to admin_level_change_applications_path, 
                  notice: 'レベル変更申請をキャンセルしました。'
    else
      redirect_to admin_level_change_applications_path, 
                  alert: '申請のキャンセルに失敗しました。'
    end
  end

  private

  def set_application
    @application = LevelChangeApplication.find(params[:id])
  end
end