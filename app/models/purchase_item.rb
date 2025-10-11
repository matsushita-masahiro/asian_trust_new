class PurchaseItem < ApplicationRecord
  # 🔗 関連
  belongs_to :purchase
  belongs_to :product

  # バリデーション
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :seller_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # 💰 合計金額（単価 × 数量）
  def total_price
    unit_price * quantity
  end

  # 💰 販売店の購入金額（販売店購入単価 × 数量）
  def seller_total_price
    seller_price * quantity
  end

  # 💰 単品あたりのボーナス（販売価格 - 販売店購入単価）
  def unit_bonus
    unit_price - seller_price
  end

  # 💰 総ボーナス（単品ボーナス × 数量）
  def total_bonus
    unit_bonus * quantity
  end

  # 委譲メソッド
  delegate :user, :buyer, :purchased_at, to: :purchase
end