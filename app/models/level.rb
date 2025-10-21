# app/models/level.rb
class Level < ApplicationRecord
    
  has_many :product_prices
  has_many :products, through: :product_prices
  has_many :users

  validates :name, presence: true
  validates :value, presence: true, uniqueness: true

  # シンボル変換（例: id: 1 → :company）
  def symbol
    case id
    when 1 then :company           # アジアビジネストラスト
    when 2 then :special_agent     # 総代理店
    when 3 then :agent             # 代理店
    when 4 then :advisor           # アドバイザー
    when 5 then :salon             # サロン
    when 6 then :clinic            # クリニック
    when 7 then :supporter         # サポーター
    when 8 then :customer          # お客様
    else :unknown
    end
  end



  # クラスメソッド：IDからレベルを取得
  def self.find_by_symbol(symbol)
    case symbol
    when :company then find(1)
    when :special_agent then find(2)
    when :agent then find(3)
    when :advisor then find(4)
    when :salon then find(5)
    when :clinic then find(6)
    when :supporter then find(7)
    when :customer then find(8)
    else nil
    end
  end

  # インセンティブ受給対象かどうかを判定
  def incentive_eligible?
    [1, 2, 3, 4, 7].include?(id)
  end

  # クラスメソッド：インセンティブ受給対象レベルを取得
  def self.incentive_eligible_levels
    where(id: [1, 2, 3, 4, 7])
  end

  # インセンティブ受給対象外かどうかを判定
  def incentive_ineligible?
    [5, 6, 8].include?(id) # サロン、クリニック、お客様
  end
end
