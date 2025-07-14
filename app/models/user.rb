class User < ApplicationRecord
  # Devise（認証機能）
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :confirmable, :lockable

  # 紹介者との関係
  belongs_to :referrer, class_name: 'User', foreign_key: 'referred_by_id', optional: true
  has_many   :referrals, class_name: 'User', foreign_key: 'referred_by_id'

  # 代理店レベル（enumを使わず独自定義）
  LEVELS = {
    company:        0,
    special_agent:  1,
    agent:          2,
    advisor:        3,
    salon:          4,
    hospital:       5,
    other:          6
  }.freeze

  LEVEL_NAMES = {
    company:        'アジアビジネストラスト',
    special_agent:  '特約代理店',
    agent:          '代理店',
    advisor:        'アドバイザー',
    salon:          'サロン',
    hospital:       '病院',
    other:          'その他'
  }.freeze

  def level_symbol
    LEVELS.key(self.level)
  end

  def level_label
    LEVEL_NAMES[level_symbol]
  end


  # 紹介可能な相手のレベルか？（レベル値比較）
  def can_introduce?(other_level_value)
    level.present? && level <= other_level_value
  end

  # 紹介階層の制約バリデーション
  validate :check_level_hierarchy
  
  # 上位紹介者のリスト（階層付き）
  def ancestors
    result = []
    current = self.referrer
    while current
      result << current
      current = current.referrer
    end
    result
  end

  # 下位紹介者の全リスト（再帰的）
  def descendants
    referrals.flat_map { |child| [child] + child.descendants }
  end

  private

  def check_level_hierarchy
    return unless referrer&.level.present? && level.present?
  
    if level < referrer.level
      errors.add(:level, "紹介者より上のレベルには設定できません")
    end
  end

end
