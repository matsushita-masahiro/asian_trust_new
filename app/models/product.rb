class Product < ApplicationRecord
    has_many :product_prices, dependent: :destroy
    has_many :levels, through: :product_prices
    accepts_nested_attributes_for :product_prices, allow_destroy: true, reject_if: proc { |attr| attr['price'].blank? }
    
    def display_unit
      "#{unit_quantity}#{unit_label}"
    end
    
    # app/models/product.rb
    def price_for(level_symbol)
      case level_symbol&.to_sym
      when :salon
        price_for_salon
      when :advisor
        price_for_advisor
      when :agent
        price_for_agent
      when :special_agent
        price_for_special_agent
      else
        nil
      end
    end



end
