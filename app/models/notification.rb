class Notification < ApplicationRecord
  belongs_to :user
  
  # 通知タイプ
  CLINIC_RESERVATION_REQUIRED = 'clinic_reservation_required'  # クリニック予約必要
  CLINIC_RESERVATION_CONFIRMED = 'clinic_reservation_confirmed'  # クリニック予約確定
  
  validates :notification_type, presence: true
  validates :title, presence: true
  
  # 新しい順に並べる
  scope :recent, -> { order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }
  
  # 既読にする
  def mark_as_read!
    update(read_at: Time.current) if read_at.nil?
  end
  
  # 未読かどうか
  def unread?
    read_at.nil?
  end
end
