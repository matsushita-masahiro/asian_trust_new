class ClinicBreakTime < ApplicationRecord
  belongs_to :clinic
  
  validates :weekday, presence: true, inclusion: { in: 0..6 }
  validates :start_time, :end_time, presence: true
  
  validate :end_time_after_start_time
  
  private
  
  def end_time_after_start_time
    return unless start_time && end_time
    
    if end_time <= start_time
      errors.add(:end_time, "は開始時間より後である必要があります")
    end
  end
end