class ProductPrice < ApplicationRecord
  belongs_to :product
  belongs_to :level

  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
