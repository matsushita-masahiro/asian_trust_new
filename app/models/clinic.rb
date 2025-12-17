class Clinic < ApplicationRecord
  belongs_to :user
  has_many :clinic_business_hours, dependent: :destroy
  has_many :clinic_break_times, dependent: :destroy
  has_many :clinic_holidays, dependent: :destroy
  has_many :clinic_reservations, dependent: :destroy
  
  # ネストした属性の受け入れを許可
  accepts_nested_attributes_for :clinic_business_hours, allow_destroy: true, reject_if: :reject_business_hours
  accepts_nested_attributes_for :clinic_break_times, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :clinic_holidays, allow_destroy: true, reject_if: :reject_holidays
  
  validates :name, presence: true
  validates :user_id, presence: true, uniqueness: true
  validates :is_active, inclusion: { in: [true, false] }
  
  # 予約可能かどうかの判定
  def reservable?
    is_active && user.present? && user.level&.name&.include?('クリニック')
  end
  
  # 指定日が祝日かどうかを判定
  def holiday?(date)
    require 'holiday_jp'
    HolidayJp.holiday?(date)
  end
  
  # 指定日の祝日名を取得
  def holiday_name(date)
    require 'holiday_jp'
    holiday = HolidayJp.between(date, date).first
    holiday&.name
  end
  
  # 指定日が予約可能かどうかを判定
  def available_for_reservation?(date)
    # クリニックがアクティブでない場合は予約不可
    return false unless reservable?
    
    # 特定日の休日設定をチェック
    return false if clinic_holidays.where(date: date).exists?
    
    # 曜日による定休日をチェック
    return false if clinic_holidays.where(weekday: date.wday).exists?
    
    # 祝日休業が有効で、指定日が祝日の場合は予約不可
    return false if holiday_closure_enabled? && holiday?(date)
    
    # 営業時間が設定されているかチェック
    business_hour = clinic_business_hours.find_by(weekday: date.wday)
    return false if business_hour.nil? || business_hour.start_time.nil? || business_hour.end_time.nil?
    
    true
  end
  
  private
  
  # 営業時間が空の場合は拒否（休診日として扱う）
  def reject_business_hours(attributes)
    # 既存のレコードで時間が空の場合は削除
    if attributes['id'].present? && attributes['start_time'].blank? && attributes['end_time'].blank?
      attributes['_destroy'] = '1'
      return false
    end
    
    # 新規レコードで時間が空の場合は拒否
    attributes['start_time'].blank? && attributes['end_time'].blank?
  end
  
  # 休日設定が空の場合は拒否
  def reject_holidays(attributes)
    attributes['reason'].blank? || (attributes['date'].blank? && attributes['weekday'].blank?)
  end
end