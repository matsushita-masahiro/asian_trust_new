# app/models/level.rb
class Level < ApplicationRecord
    
  has_many :product_prices
  has_many :products, through: :product_prices
  has_many :users

  validates :name, presence: true
  validates :value, presence: true, uniqueness: true

  # シンボル変換（例: value: 2 → :agent）
  def symbol
    case value
    when 0 then :company
    when 1 then :special_agent
    when 2 then :agent
    when 3 then :advisor
    when 4 then :salon
    when 5 then :hospital
    when 6 then :other
    else :unknown
    end
  end
end
