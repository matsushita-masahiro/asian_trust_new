class Clinic::AvailabilityService
  def initialize(clinic)
    @clinic = clinic
  end
  
  # 指定日の予約可能な1時間枠を返す
  def available_slots(date)
    return [] if holiday?(date)
    
    business_slots = generate_business_slots(date)
    break_slots = generate_break_slots(date)
    reserved_slots = reserved_slots_for(date)
    
    business_slots - break_slots - reserved_slots
  end
  
  # 休日判定
  def holiday?(date)
    weekday = date.wday
    
    # 日付指定の休日
    @clinic.clinic_holidays.where(date: date).exists? ||
    # 曜日指定の休日
    @clinic.clinic_holidays.where(weekday: weekday, date: nil).exists?
  end
  
  # 指定曜日の営業時間を取得
  def business_hours_for(weekday)
    @clinic.clinic_business_hours.find_by(weekday: weekday)
  end
  
  private
  
  def generate_business_slots(date)
    weekday = date.wday
    business_hour = business_hours_for(weekday)
    return [] unless business_hour
    
    slots = []
    current_time = business_hour.start_time
    
    while current_time < business_hour.end_time
      next_time = current_time + 1.hour
      break if next_time > business_hour.end_time
      
      slots << "#{current_time.strftime('%H:%M')}-#{next_time.strftime('%H:%M')}"
      current_time = next_time
    end
    
    slots
  end
  
  def generate_break_slots(date)
    weekday = date.wday
    break_times = @clinic.clinic_break_times.where(weekday: weekday)
    
    break_slots = []
    break_times.each do |break_time|
      current_time = break_time.start_time
      
      while current_time < break_time.end_time
        next_time = current_time + 1.hour
        break if next_time > break_time.end_time
        
        break_slots << "#{current_time.strftime('%H:%M')}-#{next_time.strftime('%H:%M')}"
        current_time = next_time
      end
    end
    
    break_slots
  end
  
  def reserved_slots_for(date)
    @clinic.clinic_reservations
           .where(status: ClinicReservation::CONFIRMED)
           .where("DATE(confirmed_date) = ?", date)
           .pluck(:confirmed_time)
           .compact
  end
end