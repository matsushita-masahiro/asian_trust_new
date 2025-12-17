module ApplicationHelper
    
    def month_options
        start_month = Date.new(2025, 4, 1)
        today = Date.today
        months = []
    
        while start_month <= today
          months << [start_month.strftime("%Y年%-m月度"), start_month.strftime("%Y-%m")]
          start_month = start_month.next_month
        end
    
        months.reverse # 新しい順
     end

     def format_postal_code(postal_code)
      postal_code.to_s.insert(3, '-')
     end

     # 消費税率を取得
     def tax_rate
       ENV.fetch('TAX_RATE', '0.1').to_f
     end

     # 消費税率をパーセント表示で取得
     def tax_rate_percentage
       (tax_rate * 100).to_i
     end

     # 消費税を計算
     def calculate_tax(amount)
       (amount.to_f * tax_rate).to_i
     end

     # 税込み金額を計算
     def calculate_total_with_tax(amount)
       amount.to_i + calculate_tax(amount)
     end

     # 階層図用: 全下位ユーザー数を再帰的に計算
     def count_all_descendants(user)
       count = user.referrals.count
       user.referrals.each do |child|
         count += count_all_descendants(child)
       end
       count
     end

     # 階層図用: 階層データを構築
     def build_hierarchy_node(user)
       {
         user: user,
         children: user.referrals.includes(:level, :wott_level, :referrals).map do |child|
           build_hierarchy_node(child)
         end
       }
     end

     # 30分刻みの時間オプションを生成（07:00-23:00）
     def time_options_30min
       options = []
       (7..23).each do |hour|
         [0, 30].each do |minute|
           time_str = sprintf("%02d:%02d", hour, minute)
           options << [time_str, time_str]
         end
       end
       options
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

     # 祝日バッジを表示
     def holiday_badge(date)
       if holiday?(date)
         content_tag :span, "祝日", class: "badge bg-danger me-1"
       end
     end

     # 祝日情報を表示
     def holiday_info(date)
       if holiday?(date)
         content_tag :small, holiday_name(date), class: "text-danger d-block"
       end
     end

     # クリニックの営業時間を表示用にフォーマット
     def format_clinic_business_hours(clinic)
       return "営業時間情報なし" unless clinic&.clinic_business_hours&.any?
       
       business_hours = clinic.clinic_business_hours.order(:weekday)
       hours_text = []
       
       business_hours.each do |hour|
         day_name = %w[日 月 火 水 木 金 土][hour.weekday]
         if hour.start_time && hour.end_time
           hours_text << "#{day_name}: #{hour.start_time.strftime('%H:%M')}～#{hour.end_time.strftime('%H:%M')}"
         end
       end
       
       hours_text.join('<br>').html_safe
     end

     # クリニックの休憩時間を表示用にフォーマット（営業時間内のみ）
     def format_clinic_break_times(clinic)
       return nil unless clinic&.clinic_break_times&.any? && clinic&.clinic_business_hours&.any?
       
       break_times = clinic.clinic_break_times.order(:weekday, :start_time)
       business_hours = clinic.clinic_business_hours.index_by(&:weekday)
       break_text = []
       
       break_times.each do |break_time|
         next unless break_time.start_time && break_time.end_time
         
         # 同じ曜日の営業時間を取得
         business_hour = business_hours[break_time.weekday]
         next unless business_hour&.start_time && business_hour&.end_time
         
         # 休憩時間が営業時間内にあるかチェック
         if break_time.start_time >= business_hour.start_time && 
            break_time.end_time <= business_hour.end_time
           day_name = %w[日 月 火 水 木 金 土][break_time.weekday]
           break_text << "#{day_name}: #{break_time.start_time.strftime('%H:%M')}～#{break_time.end_time.strftime('%H:%M')}"
         end
       end
       
       break_text.any? ? break_text.join('<br>').html_safe : nil
     end

     # クリニックの休診日を表示用にフォーマット
     def format_clinic_holidays(clinic)
       return nil unless clinic&.clinic_holidays&.any?
       
       holidays = clinic.clinic_holidays.order(:weekday, :date)
       holiday_text = []
       
       holidays.each do |holiday|
         if holiday.weekday.present?
           day_name = %w[日 月 火 水 木 金 土][holiday.weekday]
           holiday_text << "#{day_name}曜日"
         elsif holiday.date.present?
           holiday_text << holiday.date.strftime('%Y/%m/%d')
         end
       end
       
       # 祝日休業設定も追加
       if clinic.holiday_closure_enabled?
         holiday_text << "祝日"
       end
       
       holiday_text.any? ? holiday_text.join('・') : nil
     end

     # クリニックの営業時間データをJavaScript用にJSON形式で出力
     def clinic_schedule_json(clinic)
       return '{}' unless clinic

       schedule_data = {
         business_hours: {},
         break_times: {},
         holidays: {
           weekdays: [],
           dates: [],
           holiday_closure_enabled: clinic.holiday_closure_enabled?
         }
       }

       # 営業時間
       clinic.clinic_business_hours.each do |hour|
         if hour.start_time && hour.end_time
           schedule_data[:business_hours][hour.weekday] = {
             start: hour.start_time.strftime('%H:%M'),
             end: hour.end_time.strftime('%H:%M')
           }
         end
       end

       # 休憩時間
       clinic.clinic_break_times.each do |break_time|
         if break_time.start_time && break_time.end_time
           schedule_data[:break_times][break_time.weekday] ||= []
           schedule_data[:break_times][break_time.weekday] << {
             start: break_time.start_time.strftime('%H:%M'),
             end: break_time.end_time.strftime('%H:%M')
           }
         end
       end

       # 休日
       clinic.clinic_holidays.each do |holiday|
         if holiday.weekday.present?
           schedule_data[:holidays][:weekdays] << holiday.weekday
         elsif holiday.date.present?
           schedule_data[:holidays][:dates] << holiday.date.strftime('%Y-%m-%d')
         end
       end

       schedule_data.to_json.html_safe
     end

     # クリニックの利用可能時間スロットを生成
     def generate_available_time_slots(clinic, weekday)
       return [] unless clinic&.clinic_business_hours&.any?

       business_hour = clinic.clinic_business_hours.find { |bh| bh.weekday == weekday }
       return [] unless business_hour&.start_time && business_hour&.end_time

       slots = []
       current_time = business_hour.start_time
       end_time = business_hour.end_time

       # 30分刻みでスロットを生成
       while current_time < end_time
         slot_end = current_time + 1.hour
         slot_end = end_time if slot_end > end_time

         # 休憩時間と重複しないかチェック
         break_times = clinic.clinic_break_times.where(weekday: weekday)
         is_break_time = break_times.any? do |bt|
           bt.start_time && bt.end_time &&
           current_time < bt.end_time && slot_end > bt.start_time
         end

         unless is_break_time
           slots << "#{current_time.strftime('%H:%M')}-#{slot_end.strftime('%H:%M')}"
         end

         current_time += 1.hour
       end

       slots
     end
    
end
