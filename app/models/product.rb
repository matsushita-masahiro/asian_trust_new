class Product < ApplicationRecord
    has_many :product_prices, dependent: :destroy
    has_many :levels, through: :product_prices
    accepts_nested_attributes_for :product_prices, allow_destroy: true, reject_if: proc { |attr| attr['price'].blank? }
    
    def display_unit
      "#{unit_quantity}#{unit_label}"
    end
    
    def price_for(level_symbol)
      return nil unless level_symbol
      
      # レベルシンボルからレベルを検索
      level = Level.all.find { |l| l.symbol == level_symbol.to_sym }
      return nil unless level
      
      product_price = product_prices.find_by(level: level)
      product_price&.price
    end



end
