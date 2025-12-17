class AddDefaultHolidaysToExistingClinics < ActiveRecord::Migration[8.0]
  def up
    # 既存のクリニックに日曜日と祝日の休日設定を追加
    Clinic.find_each do |clinic|
      # 日曜日を休日に設定（weekday: 0 = 日曜日）
      unless clinic.clinic_holidays.exists?(weekday: 0)
        clinic.clinic_holidays.create!(
          weekday: 0,
          reason: "日曜日"
        )
      end
      
      # 祝日を休日に設定（特定の日付ではなく、一般的な祝日として）
      # 実際の祝日は別途管理する必要がありますが、ここでは基本設定として追加
      puts "Added default holidays for clinic: #{clinic.name}"
    end
  end
  
  def down
    # 日曜日の休日設定を削除
    ClinicHoliday.where(weekday: 0, reason: "日曜日").destroy_all
  end
end