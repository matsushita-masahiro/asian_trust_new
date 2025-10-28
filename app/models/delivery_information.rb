class DeliveryInformation < ApplicationRecord
  belongs_to :purchase
  belongs_to :clinic, class_name: 'User', optional: true

  # バリデーション
  validates :delivery_type, presence: true, inclusion: { in: %w[home clinic multiple] }
  validates :address_type, inclusion: { in: %w[registration shipping] }, allow_blank: true
  validates :clinic_id, presence: true, if: -> { delivery_type.in?(%w[clinic multiple]) }
  validates :delivery_address, presence: true

  # スコープ
  scope :home_delivery, -> { where(delivery_type: 'home') }
  scope :clinic_delivery, -> { where(delivery_type: 'clinic') }
  scope :multiple_delivery, -> { where(delivery_type: 'multiple') }

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

  def clinic_name
    clinic&.name
  end

  def formatted_delivery_address
    delivery_address&.gsub(/\|/, "\n")
  end
end