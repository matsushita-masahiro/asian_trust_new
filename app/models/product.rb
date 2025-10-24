class Product < ApplicationRecord
    has_many :product_prices, dependent: :destroy
    has_many :levels, through: :product_prices
    accepts_nested_attributes_for :product_prices, allow_destroy: true, reject_if: proc { |attr| attr['price'].blank? }
    
    # 論理削除のスコープ
    scope :active, -> { where(deleted_at: nil) }
    scope :deleted, -> { where.not(deleted_at: nil) }
    
    def display_unit
      "#{unit_quantity}#{unit_label}"
    end
    
    def display_name
      short_name.present? ? short_name : name
    end
    
    def price_for(level_symbol)
      return nil unless level_symbol
      
      # レベルシンボルからレベルを検索
      level = Level.all.find { |l| l.symbol == level_symbol.to_sym }
      return nil unless level
      
      product_price = product_prices.find_by(level: level)
      product_price&.price
    end
    
    # 論理削除メソッド
    def soft_delete
      update(deleted_at: Time.current)
    end
    
    # 論理削除の復元メソッド
    def restore
      update(deleted_at: nil)
    end
    
    # 削除済みかどうかの判定
    def deleted?
      deleted_at.present?
    end
    
    # アクティブかどうかの判定
    def active?
      deleted_at.nil?
    end
end
