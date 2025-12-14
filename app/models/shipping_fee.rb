class ShippingFee < ApplicationRecord
  belongs_to :purchase

  # 送料タイプのenum
  enum :shipping_type, {
    standard: 'standard',         # 通常配送
    bone_marrow: 'bone_marrow',   # 骨髄別送
    clinic_delivery: 'clinic_delivery',     # クリニック配送
    home_delivery: 'home_delivery',         # 自宅配送
    other_delivery: 'other_delivery'        # その他配送
  }

  # バリデーション
  validates :shipping_type, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # スコープ
  scope :by_type, ->(type) { where(shipping_type: type) }

  # 送料タイプの日本語名
  def shipping_type_name
    case shipping_type
    when 'standard'
      '送料'
    when 'bone_marrow'
      '骨髄別送'
    when 'clinic_delivery'
      '送料（クリニック配送）'
    when 'home_delivery'
      '送料（登録住所）'
    when 'other_delivery'
      '送料（その他お届け先）'
    else
      shipping_type
    end
  end
end
