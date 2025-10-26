class WottLevel < ApplicationRecord
  has_many :users, foreign_key: 'wott_level_id', dependent: :nullify
  
  validates :name, presence: true, uniqueness: true
  validates :value, presence: true, uniqueness: true
  
  scope :ordered, -> { order(:value) }
  
  def symbol
    case name
    when 'アジアビジネストラスト'
      :abt
    when '総代理店'
      :special_agent
    when '代理店'
      :agent
    when 'アドバイザー'
      :advisor
    when 'サポーター'
      :supporter
    when 'サロン'
      :salon
    when 'クリニック'
      :clinic
    when 'お客様'
      :customer
    else
      :unknown
    end
  end
end
