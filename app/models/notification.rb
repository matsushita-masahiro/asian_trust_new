class Notification < ApplicationRecord
  belongs_to :user
  
  # 通知タイプ
  CLINIC_RESERVATION_REQUIRED = 'clinic_reservation_required'  # クリニック予約必要
  CLINIC_RESERVATION_CONFIRMED = 'clinic_reservation_confirmed'  # クリニック予約確定
  PAYMENT_CONFIRMED = 'payment_confirmed'  # 入金確認完了
  RECEIPT_ISSUED = 'receipt_issued'  # 領収書発行完了
  RECEIPT_REQUEST = 'receipt_request'  # 領収書発行依頼
  EMERGENCY_RESERVATION_REQUESTED = 'emergency_reservation_requested'  # 緊急予約依頼
  INCENTIVE_PAYMENT_COMPLETED = 'incentive_payment_completed'  # インセンティブ振込完了
  
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
