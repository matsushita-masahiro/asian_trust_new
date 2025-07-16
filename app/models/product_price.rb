class ProductPrice < ApplicationRecord
  belongs_to :product
  belongs_to :level

  validates :price, presence: true, numericality: { greater_than: 0 }
end
