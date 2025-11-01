class Product < ApplicationRecord
    has_many :product_prices, dependent: :destroy
    has_many :levels, through: :product_prices
    accepts_nested_attributes_for :product_prices, allow_destroy: true, reject_if: proc { |attr| attr['price'].blank? }
    
    # 論理削除のスコープ
    scope :active, -> { where(deleted_at: nil, is_active: true) }
    scope :deleted, -> { where.not(deleted_at: nil) }
    
    def display_unit
      # 整数の場合は小数点を表示しない
      formatted_quantity = unit_quantity % 1 == 0 ? unit_quantity.to_i : unit_quantity
      "#{formatted_quantity}#{unit_label}"
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
    
    # WOTT level price method - WOTT商品は全員一律base_price
    def wott_price_for(wott_level_symbol)
      return nil unless wott_level_symbol
      
      # WOTT商品は全員一律でbase_price（1,100,000円）を返す
      if category == 'wott'
        return base_price
      end
      
      # 他のカテゴリの場合は従来通りの価格設定を使用
      wott_level_name = case wott_level_symbol.to_sym
      when :abt
        'アジアビジネストラスト'
      when :special_agent
        '総代理店'
      when :agent
        '代理店'
      when :supporter
        'サポーター'
      when :salon
        'サロン'
      when :clinic
        'クリニック'
      when :customer
        'お客様'
      else
        return nil
      end
      
      wott_level = WottLevel.find_by(name: wott_level_name)
      return nil unless wott_level
      
      product_price = product_prices.find_by(wott_level: wott_level)
      product_price&.price
    end
    
    # Get price based on product category and user level
    def price_for_user(user)
      return nil unless user
      
      case category
      when 'wott'
        # WOTT商品は全員一律でbase_price（1,100,000円）
        return base_price
      when 'sl', 'ms', 'ag'
        return price_for(user.level&.symbol)
      end
      
      # Fallback to base_price if no specific price found
      base_price
    end
    
    # WOTT商品のインセンティブ計算（データベースから取得）
    def wott_incentive_for(user)
      return 0 unless category == 'wott' && user&.has_wott_level?
      
      # データベースに保存されたインセンティブ額を取得
      wott_level = user.wott_level
      return 0 unless wott_level
      
      price_record = product_prices.find_by(wott_level: wott_level)
      return price_record&.price || 0
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
      deleted_at.nil? && is_active?
    end
    
    # カテゴリー別のスコープ
    scope :stem_cell, -> { where(category: 'sl') }
    scope :mannersound, -> { where(category: 'ms') }
    scope :wott, -> { where(category: 'wott') }
    scope :airgun, -> { where(category: 'ag') }
    
    # カテゴリー名を取得
    def category_name
      case category
      when 'sl'
        '幹細胞培養上清液'
      when 'ms'
        'MANNERSOUND'
      when 'wott'
        'WOTT'
      when 'ag'
        'エアガン'
      else
        'その他'
      end
    end
    
    # 送料タイプを判定
    def shipping_type
      if id == 1
        'bone_marrow'  # 骨髄別送
      else
        'standard'     # 通常配送
      end
    end
    
    # 送料タイプの日本語名
    def shipping_type_name
      case shipping_type
      when 'bone_marrow'
        '骨髄別送'
      else
        '通常配送'
      end
    end
    
    # 送料金額を取得（現在は両方とも6000円）
    def shipping_fee_amount
      6000  # 税抜き6000円
    end
end
