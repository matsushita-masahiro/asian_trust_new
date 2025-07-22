class User < ApplicationRecord
  # Devise（認証機能）
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :confirmable, :lockable

  # 紹介者との関係
  belongs_to :referrer, class_name: 'User', foreign_key: 'referred_by_id', optional: true
  has_many   :referrals, class_name: 'User', foreign_key: 'referred_by_id'
  has_many   :referred_users, class_name: 'User', foreign_key: 'referred_by_id'

  # 会員レベル
  belongs_to :level
  has_many :purchases

  # ステータス管理
  enum :status, {
    active: 'active',       # アクティブ（通常状態）
    inactive: 'inactive',   # 退会
    suspended: 'suspended'  # 停止処分
  }

  BONUS_ELIGIBLE_LEVELS = %w[特約代理店 代理店 アドバイザー].freeze

  # スコープ
  scope :active_users, -> { where(status: 'active') }
  scope :inactive_users, -> { where(status: 'inactive') }
  scope :suspended_users, -> { where(status: 'suspended') }

  def can_introduce?(other_level_value)
    level&.value.present? && level.value <= other_level_value
  end

  def level_symbol
    level&.symbol
  end

  def level_label
    level&.name
  end

  def display_name
    name.present? ? "#{name} (#{email})" : email
  end

  def ancestors
    result = []
    current = referrer
    while current
      result << current
      current = current.referrer
    end
    result
  end

  def descendants
    referrals.flat_map { |child| [child] + child.descendants }
  end

  def descendant_ids
    descendants.map(&:id)
  end

  def descendant_purchases
    Purchase.where(user_id: descendant_ids)
  end

  def all_purchases_including_self
    Purchase.where(user_id: [id] + descendant_ids)
  end

  def own_monthly_sales_total(month_str)
    purchases.in_month_tokyo(month_str).sum('unit_price * quantity')
  end
  
  def direct_referees_monthly_sales_total(month_str)
    referred_users.sum do |user|
      user.purchases.in_month_tokyo(month_str).sum('unit_price * quantity')
    end
  end
  
  def all_descendants_monthly_sales_total(month_str)
    descendant_purchases.in_month_tokyo(month_str).sum('unit_price * quantity')
  end
  
  def total_sales_with_descendants(month_str)
    own_monthly_sales_total(month_str) + all_descendants_monthly_sales_total(month_str)
  end


  def bonus_eligible?
    BONUS_ELIGIBLE_LEVELS.include?(level&.name)
  end

  def bonus_in_month(month_str = nil)
    return 0 unless bonus_eligible?

    month_str ||= Time.current.strftime("%Y-%m")
    from_date = Date.strptime(month_str, "%Y-%m").beginning_of_month.beginning_of_day
    to_date   = Date.strptime(month_str, "%Y-%m").end_of_month.end_of_day

    bonus_in_period(from_date, to_date)
  end

  alias_method :current_month_bonus, :bonus_in_month

  def bonus_path_up_to(ancestor)
    path = []
    current = self
    while current
      path << current
      return path.reverse if current == ancestor
      current = current.referrer
    end
    nil
  end

  def bonus_for_purchase(purchase)
    return 0 unless bonus_eligible?

    product = purchase.product
    quantity = purchase.quantity
    purchase_user = purchase.user

    # 自分の販売か？
    if purchase_user == self
      base_price = product.base_price
      my_price = product.product_prices.find_by(level_id: level_id)&.price || 0
      return (base_price - my_price) * quantity
    end

    # 自分の直下の無資格者の販売か？
    if referrals.include?(purchase_user) && !purchase_user.bonus_eligible?
      base_price = product.base_price
      my_price = product.product_prices.find_by(level_id: level_id)&.price || 0
      diff = base_price - my_price
      return diff * quantity if diff.positive?
    end

    # 子孫からの販売に対して、自分にボーナスがあるか？
    if descendant_ids.include?(purchase_user.id)
      bonus_chain = [purchase_user] + purchase_user.ancestors
      bonus_chain = bonus_chain.select(&:bonus_eligible?)

      price_map = bonus_chain.index_with do |u|
        product.product_prices.find_by(level_id: u.level_id)&.price
      end

      bonus_chain.each_cons(2) do |lower, upper|
        lower_price = price_map[lower]
        upper_price = price_map[upper]
        next unless lower_price && upper_price

        if upper == self
          diff = lower_price - upper_price
          return diff * quantity if diff.positive?
        end
      end
    end

    0
  end

  def bonus_in_period(start_date, end_date)
    return 0 unless bonus_eligible?

    range = start_date..end_date
    total_bonus = 0

    # --- (1) 自分の販売に対するボーナス ---
    self_bonus = purchases.where(purchased_at: range).sum do |purchase|
      product = purchase.product
      base_price = product.base_price
      my_price = product.product_prices.find_by(level_id: level_id)&.price || 0
      (base_price - my_price) * purchase.quantity
    end
    total_bonus += self_bonus

    # --- (2) 子孫の販売に対して自分が得られるボーナス（階層差額） ---
    descendant_purchases = Purchase.includes(:product, :user)
                                   .where(user_id: descendant_ids)
                                   .where(purchased_at: range)

    descendant_purchases.each do |purchase|
      product = purchase.product
      next unless product
      quantity = purchase.quantity
      purchase_user = purchase.user

      bonus_chain = [purchase_user] + purchase_user.ancestors
      bonus_chain = bonus_chain.select(&:bonus_eligible?)

      price_map = bonus_chain.index_with do |u|
        product.product_prices.find_by(level_id: u.level_id)&.price
      end

      bonus_chain.each_cons(2) do |lower, upper|
        lower_price = price_map[lower]
        upper_price = price_map[upper]
        next unless lower_price && upper_price
        if upper == self
          diff = lower_price - upper_price
          total_bonus += diff * quantity if diff.positive?
        end
      end
    end

    # --- (3) 直下の無資格者による販売に対するボーナス ---
    referrals.reject(&:bonus_eligible?).each do |child|
      child.purchases.where(purchased_at: range).each do |purchase|
        product = purchase.product
        base_price = product.base_price
        my_price = product.product_prices.find_by(level_id: level_id)&.price || 0
        diff = base_price - my_price
        total_bonus += diff * purchase.quantity if diff.positive?
      end
    end

    total_bonus
  end

  def bonus_from_descendants(start_date, end_date)
    descendant_ids = self.descendants.pluck(:id)

    total_bonus = 0

    Purchase.includes(:user, :product)
            .where(user_id: descendant_ids)
            .where(purchased_at: start_date..end_date)
            .find_each do |purchase|

      buyer = purchase.user
      product = purchase.product
      quantity = purchase.quantity
      base_price = product.base_price
      buyer_price = ProductPrice.find_by(level_id: buyer.level, product_id: product.id)&.price

      current = buyer
      while current.referred_by_id && current.referred_by_id != self.id
        current = User.find_by(id: current.referred_by_id)
        return 0 unless current
      end

      if buyer_price && base_price && buyer_price < base_price
        total_bonus += (base_price - buyer_price) * quantity
      end
    end

    total_bonus
  end

  def bonus_from_user(user, from_date, to_date)
    purchases = user.purchases.in_period(from_date, to_date)

    purchases.sum do |purchase|
      calculate_bonus_for(purchase)
    end
  end

  private

  def check_level_hierarchy
    return unless referrer&.level&.value && level&.value
    if level.value < referrer.level.value
      errors.add(:level, "紹介者より上のレベルには設定できません")
    end
  end
end
