class DeliveryInformation < ApplicationRecord
  belongs_to :purchase
  belongs_to :clinic, optional: true

  # バリデーション
  validates :delivery_type, presence: true, inclusion: { in: %w[home clinic multiple other] }
  validates :address_type, inclusion: { in: %w[registration shipping] }, allow_blank: true
  validates :clinic_id, presence: true, if: -> { delivery_type.in?(%w[clinic multiple]) }
  validates :delivery_address, presence: true
  
  # 'other'タイプの場合の必須フィールド
  validates :recipient_name, presence: true, if: -> { delivery_type == 'other' }
  validates :postal_code, presence: true, if: -> { delivery_type == 'other' }
  validates :phone_number, presence: true, if: -> { delivery_type == 'other' }

  # スコープ
  scope :home_delivery, -> { where(delivery_type: 'home') }
  scope :clinic_delivery, -> { where(delivery_type: 'clinic') }
  scope :multiple_delivery, -> { where(delivery_type: 'multiple') }
  scope :other_delivery, -> { where(delivery_type: 'other') }

  # メソッド
  def home_delivery?
    delivery_type == 'home'
  end

  def clinic_delivery?
    delivery_type == 'clinic'
  end

  def multiple_delivery?
    delivery_type == 'multiple'
  end

  def other_delivery?
    delivery_type == 'other'
  end

  def clinic_name
    clinic&.name
  end

  def formatted_delivery_address
    delivery_address&.gsub(/\|/, "\n")
  end
end