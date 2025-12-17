class Admin::ClinicsController < Admin::BaseController
  before_action :set_clinic, only: [:show, :edit, :update, :destroy]
  
  def index
    @clinics = Clinic.includes(:user, :clinic_business_hours, :clinic_break_times, :clinic_holidays)
                     .order(:name)
    
    # 予約可能クリニックとして未登録のクリニックユーザー
    @available_clinic_users = User.joins(:level)
                                  .where(levels: { name: 'クリニック' })
                                  .where.not(id: Clinic.select(:user_id))
                                  .order(:name)
  end
  
  def show
    @business_hours = @clinic.clinic_business_hours.order(:weekday)
    @break_times = @clinic.clinic_break_times.order(:weekday, :start_time)
    @holidays = @clinic.clinic_holidays.order(:date, :weekday)
    @reservations = @clinic.clinic_reservations.includes(:user, :purchase).order(created_at: :desc).limit(10)
  end
  
  def new
    @clinic = Clinic.new
    @available_clinic_users = User.joins(:level)
                                  .where(levels: { name: 'クリニック' })
                                  .where.not(id: Clinic.select(:user_id))
                                  .order(:name)
    
    # 営業時間の初期化（全曜日分）
    (0..6).each do |weekday|
      @clinic.clinic_business_hours.build(weekday: weekday)
    end
  end
  
  def create
    @clinic = Clinic.new(clinic_params)
    
    if @clinic.save
      redirect_to admin_clinic_path(@clinic), notice: 'クリニックが正常に作成されました。'
    else
      @available_clinic_users = User.joins(:level)
                                    .where(levels: { name: 'クリニック' })
                                    .where.not(id: Clinic.select(:user_id))
                                    .order(:name)
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    # 営業時間の初期化（全曜日分）
    # 既存のオブジェクトをメモリに読み込み
    @clinic.clinic_business_hours.load
    
    (0..6).each do |weekday|
      unless @clinic.clinic_business_hours.any? { |bh| bh.weekday == weekday }
        @clinic.clinic_business_hours.build(weekday: weekday)
      end
    end
  end
  
  def update
    if @clinic.update(clinic_params)
      redirect_to admin_clinic_path(@clinic), notice: 'クリニック設定を更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @clinic.destroy
    redirect_to admin_clinics_path, notice: 'クリニックが削除されました。'
  end
  
  # 既存のクリニックユーザーに予約機能を追加
  def enable_reservation
    @user = User.find(params[:user_id])
    
    # 既にClinicレコードが存在するかチェック
    if @user.clinic
      redirect_to edit_admin_clinic_path(@user.clinic), 
                  notice: 'このユーザーは既に予約機能が設定されています。'
      return
    end
    
    # 新しいClinicレコードを作成
    @clinic = Clinic.new(
      user: @user,
      name: @user.name,
      is_active: true
    )
    
    if @clinic.save
      # デフォルトの営業時間を設定（月〜土 10:00-18:30、昼休憩13:00-15:00）
      (1..6).each do |weekday| # 月曜日から土曜日
        @clinic.clinic_business_hours.create!(
          weekday: weekday,
          start_time: "10:00",
          end_time: "18:30"
        )
        
        # 昼休憩を設定
        @clinic.clinic_break_times.create!(
          weekday: weekday,
          start_time: "13:00",
          end_time: "15:00"
        )
      end
      
      # 日曜日を休日に設定
      @clinic.clinic_holidays.create!(
        weekday: 0,
        reason: "日曜日"
      )
      
      redirect_to edit_admin_clinic_path(@clinic), 
                  notice: '予約機能を有効にしました。営業時間や休日を調整してください。'
    else
      redirect_to admin_clinics_path, 
                  alert: '予約機能の有効化に失敗しました。'
    end
  end
  
  private
  
  def set_clinic
    @clinic = Clinic.find(params[:id])
  end
  
  def clinic_params
    params.require(:clinic).permit(
      :user_id, :name, :is_active, :holiday_closure_enabled,
      clinic_business_hours_attributes: [:id, :weekday, :start_time, :end_time, :_destroy],
      clinic_break_times_attributes: [:id, :weekday, :start_time, :end_time, :_destroy],
      clinic_holidays_attributes: [:id, :date, :weekday, :reason, :_destroy]
    )
  end
  

end