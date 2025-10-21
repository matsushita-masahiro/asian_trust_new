# 日付範囲計算とバリデーションサービス
class DateRangeService
  class InvalidDateError < StandardError; end
  class FutureDateError < StandardError; end
  class InvalidRangeError < StandardError; end

  # 月初から指定日までの期間を計算
  def self.month_to_date_range(target_date)
    target_date = parse_date(target_date)
    validate_date(target_date)
    
    start_date = target_date.beginning_of_month.beginning_of_day
    end_date = target_date.end_of_day
    
    {
      start_date: start_date,
      end_date: end_date,
      days_count: (end_date.to_date - start_date.to_date).to_i + 1,
      month_str: target_date.strftime("%Y-%m"),
      display_range: "#{start_date.strftime('%Y年%m月%d日')} 〜 #{end_date.strftime('%Y年%m月%d日')}"
    }
  end

  # カスタム期間の計算
  def self.custom_range(start_date, end_date)
    start_date = parse_date(start_date)
    end_date = parse_date(end_date)
    
    validate_date(start_date)
    validate_date(end_date)
    validate_range(start_date, end_date)
    
    {
      start_date: start_date.beginning_of_day,
      end_date: end_date.end_of_day,
      days_count: (end_date - start_date).to_i + 1,
      display_range: "#{start_date.strftime('%Y年%m月%d日')} 〜 #{end_date.strftime('%Y年%m月%d日')}"
    }
  end

  # 現在月の範囲を取得
  def self.current_month_range
    today = Time.current.in_time_zone("Asia/Tokyo").to_date
    month_to_date_range(today)
  end

  # 前月の範囲を取得
  def self.previous_month_range
    last_month = Time.current.in_time_zone("Asia/Tokyo").prev_month
    start_date = last_month.beginning_of_month.beginning_of_day
    end_date = last_month.end_of_month.end_of_day
    
    {
      start_date: start_date,
      end_date: end_date,
      days_count: (end_date.to_date - start_date.to_date).to_i + 1,
      month_str: last_month.strftime("%Y-%m"),
      display_range: "#{start_date.strftime('%Y年%m月%d日')} 〜 #{end_date.strftime('%Y年%m月%d日')}"
    }
  end

  # 日付文字列のバリデーション
  def self.validate_date_string(date_string)
    return false if date_string.blank?
    
    begin
      parsed_date = Date.parse(date_string)
      validate_date(parsed_date)
      true
    rescue ArgumentError, InvalidDateError, FutureDateError
      false
    end
  end

  # 月文字列のバリデーション（YYYY-MM形式）
  def self.validate_month_string(month_string)
    return false if month_string.blank?
    
    begin
      Date.strptime(month_string, "%Y-%m")
      true
    rescue ArgumentError
      false
    end
  end

  # 日付範囲の妥当性チェック
  def self.valid_range?(start_date, end_date)
    begin
      start_date = parse_date(start_date)
      end_date = parse_date(end_date)
      validate_date(start_date)
      validate_date(end_date)
      validate_range(start_date, end_date)
      true
    rescue StandardError
      false
    end
  end

  # 月の最大日数を取得
  def self.days_in_month(year, month)
    Date.new(year, month, -1).day
  end

  # 営業日のみの日数を計算（土日を除く）
  def self.business_days_count(start_date, end_date)
    start_date = parse_date(start_date).to_date
    end_date = parse_date(end_date).to_date
    
    count = 0
    current_date = start_date
    
    while current_date <= end_date
      count += 1 unless current_date.saturday? || current_date.sunday?
      current_date += 1.day
    end
    
    count
  end

  private

  # 日付のパース
  def self.parse_date(date_input)
    case date_input
    when Date
      date_input
    when Time, DateTime
      date_input.to_date
    when String
      Date.parse(date_input)
    else
      raise InvalidDateError, "無効な日付形式です: #{date_input}"
    end
  rescue ArgumentError
    raise InvalidDateError, "日付の解析に失敗しました: #{date_input}"
  end

  # 日付の妥当性チェック
  def self.validate_date(date)
    today = Time.current.in_time_zone("Asia/Tokyo").to_date
    
    # 未来日チェック
    if date > today
      raise FutureDateError, "未来の日付は指定できません: #{date}"
    end
    
    # 過去すぎる日付チェック（例：5年前より古い）
    if date < today - 5.years
      raise InvalidDateError, "指定可能な日付範囲を超えています: #{date}"
    end
  end

  # 日付範囲の妥当性チェック
  def self.validate_range(start_date, end_date)
    if start_date > end_date
      raise InvalidRangeError, "開始日が終了日より後になっています"
    end
    
    # 範囲が長すぎる場合のチェック（例：1年以上）
    if (end_date - start_date).to_i > 365
      raise InvalidRangeError, "指定可能な期間は1年以内です"
    end
  end
end