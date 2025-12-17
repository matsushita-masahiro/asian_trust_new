class ClinicHoliday < ApplicationRecord
  belongs_to :clinic
  
  validates :reason, presence: true
  validate :date_or_weekday_present
  
  private
  
  def date_or_weekday_present
    if date.blank? && weekday.blank?
      errors.add(:base, "日付または曜日のいずれかを指定してください")
    end
  end
end