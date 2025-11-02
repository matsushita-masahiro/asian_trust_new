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
    when 5 then :advisor_pre       # アドバイザー認定前
    when 6 then :supporter         # サポーター
    when 7 then :clinic            # クリニック
    when 8 then :salon             # サロン
    when 9 then :customer          # お客様
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
    when :advisor_pre then find(5)
    when :supporter then find(6)
    when :clinic then find(7)
    when :salon then find(8)
    when :customer then find(9)
    else nil
    end
  end

  # インセンティブ受給対象かどうかを判定
  def incentive_eligible?
    [1, 2, 3, 4, 6].include?(id) # アジアビジネストラスト、総代理店、代理店、アドバイザー、サポーター
  end

  # クラスメソッド：インセンティブ受給対象レベルを取得
  def self.incentive_eligible_levels
    where(id: [1, 2, 3, 4, 6])
  end

  # インセンティブ受給対象外かどうかを判定
  def incentive_ineligible?
    [5, 7, 8, 9].include?(id) # アドバイザー認定前、クリニック、サロン、お客様
  end

  # 商品購入可能かどうかを判定
  def purchase_eligible?
    !name.in?(['アドバイザー認定前'])
  end

  # 紹介機能利用可能かどうかを判定
  def referral_eligible?
    [1, 2, 3, 4, 6].include?(id) # アドバイザー認定前、クリニック、サロン、お客様は紹介機能利用不可
  end

  # お客様レベルかどうかを判定
  def customer?
    name == 'お客様'
  end

  # アジアビジネストラストかどうかを判定
  def company?
    name == 'アジアビジネストラスト'
  end
end
