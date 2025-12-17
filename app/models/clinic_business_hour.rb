class ClinicBusinessHour < ApplicationRecord
  belongs_to :clinic
  
  validates :weekday, presence: true, inclusion: { in: 0..6 }
  validates :clinic_id, uniqueness: { scope: :weekday }
  
  # 開始時間と終了時間は両方設定されているか、両方空である必要がある
  validate :both_times_present_or_both_blank
  
  validate :end_time_after_start_time
  
  private
  
  def both_times_present_or_both_blank
    if start_time.present? && end_time.blank?
      errors.add(:end_time, "開始時間が設定されている場合は終了時間も設定してください")
    elsif start_time.blank? && end_time.present?
      errors.add(:start_time, "終了時間が設定されている場合は開始時間も設定してください")
    end
  end
  
  def end_time_after_start_time
    return unless start_time && end_time
    
    if end_time <= start_time
      errors.add(:end_time, "は開始時間より後である必要があります")
    end
  end
end