class ProductPrice < ApplicationRecord
  belongs_to :product
  belongs_to :level, optional: true
  belongs_to :wott_level, optional: true

  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :incentive_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: true
  validate :must_have_level_or_wott_level
  
  # インセンティブ率をパーセンテージで取得（0.2 -> 20）
  def incentive_percentage
    return nil unless incentive_rate
    (incentive_rate * 100).to_i
  end
  
  # パーセンテージからインセンティブ率を設定（20 -> 0.2）
  def incentive_percentage=(value)
    if value.present? && value.to_f > 0
      self.incentive_rate = value.to_f / 100.0
    else
      self.incentive_rate = nil
    end
  end
  
  private
  
  def must_have_level_or_wott_level
    if level.blank? && wott_level.blank?
      errors.add(:base, 'Either level or wott_level must be present')
    end
  end
end
