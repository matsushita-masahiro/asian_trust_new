class ProductPrice < ApplicationRecord
  belongs_to :product
  belongs_to :level, optional: true
  belongs_to :wott_level, optional: true

  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :must_have_level_or_wott_level
  
  private
  
  def must_have_level_or_wott_level
    if level.blank? && wott_level.blank?
      errors.add(:base, 'Either level or wott_level must be present')
    end
  end
end
