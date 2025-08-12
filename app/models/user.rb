require 'set'

class User < ApplicationRecord
  # Devise（認証機能）
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :confirmable, :lockable

  # 紹介者との関係
  belongs_to :referrer, class_name: 'User', foreign_key: 'referred_by_id', optional: true
  has_many   :referrals, class_name: 'User', foreign_key: 'referred_by_id'
  has_many   :referred_users, class_name: 'User', foreign_key: 'referred_by_id'
  # invoice関連
  has_many :invoices
  has_many :invoice_recipients
  has_one  :invoice_base

  # 会員レベル
  belongs_to :level
  has_many :purchases
  
  # レベル履歴
  has_many :user_level_histories, dependent: :destroy
  has_many :changed_level_histories, class_name: 'UserLevelHistory', foreign_key: 'changed_by_id'

  # ステータス管理
  attribute :status, :string, default: 'active'
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
    # 新しい構造：purchase_itemsから合計を計算
    Purchase.joins(:purchase_items)
            .where(user: self)
            .in_month_tokyo(month_str)
            .sum('purchase_items.unit_price * purchase_items.quantity')
  end
  
  def direct_referees_monthly_sales_total(month_str)
    referred_users.sum do |user|
      user.own_monthly_sales_total(month_str)
    end
  end
  
  def all_descendants_monthly_sales_total(month_str)
    Purchase.joins(:purchase_items)
            .where(user_id: descendant_ids)
            .in_month_tokyo(month_str)
            .sum('purchase_items.unit_price * purchase_items.quantity')
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

  # 指定月の総インセンティブを履歴ベースで計算（詳細情報付き）
  def monthly_incentive_with_details(month_str = nil)
    return { total: 0, details: {} } unless bonus_eligible?

    month_str ||= Time.current.strftime("%Y-%m")
    from_date = Date.strptime(month_str, "%Y-%m").beginning_of_month.beginning_of_day
    to_date   = Date.strptime(month_str, "%Y-%m").end_of_month.end_of_day

    details = {
      own_sales: 0,           # 自分の販売によるインセンティブ
      descendant_sales: 0,    # 子孫の販売による階層差額
      unqualified_sales: 0,   # 無資格者の販売によるインセンティブ
      purchase_count: 0,      # 対象購入件数
      level_changes: []       # 期間中のレベル変更履歴
    }

    # 期間中のレベル変更履歴を取得
    level_histories = user_level_histories
                     .where(effective_from: from_date..to_date)
                     .includes(:level, :previous_level, :changed_by)
                     .order(:effective_from)

    details[:level_changes] = level_histories.map do |history|
      {
        date: history.effective_from,
        from_level: history.previous_level&.name,
        to_level: history.level.name,
        reason: history.change_reason,
        changed_by: history.changed_by&.name
      }
    end

    # --- (1) 自分の販売に対するインセンティブ ---
    my_purchase_items = PurchaseItem.joins(:purchase)
                                   .where(purchases: { user_id: id, purchased_at: from_date..to_date })
                                   .includes(:product, purchase: :user)

    my_purchase_items.each do |item|
      purchase_date = item.purchase.purchased_at
      my_level_at_purchase = level_at(purchase_date)
      product = item.product
      base_price = product.base_price
      my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
      
      item_bonus = (base_price - my_price) * item.quantity
      details[:own_sales] += item_bonus if item_bonus > 0
      details[:purchase_count] += 1
    end

    # --- (2) 子孫の販売に対するインセンティブ（階層差額） ---
    descendant_user_ids = descendant_ids.reject { |uid| uid == id }
    
    if descendant_user_ids.any?
      descendant_purchase_items = PurchaseItem.joins(:purchase)
                                             .where(purchases: { user_id: descendant_user_ids, purchased_at: from_date..to_date })
                                             .includes(:product, purchase: :user)

      descendant_purchase_items.each do |item|
        purchase = item.purchase
        purchase_date = purchase.purchased_at
        purchase_user_level = purchase.user.level_at(purchase_date)
        my_level_at_purchase = level_at(purchase_date)
        
        product = item.product
        purchase_user_price = product.product_prices.find_by(level_id: purchase_user_level.id)&.price || 0
        my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
        
        if purchase_user_price > my_price
          diff = purchase_user_price - my_price
          item_bonus = diff * item.quantity
          details[:descendant_sales] += item_bonus
          details[:purchase_count] += 1
        end
      end
    end

    # --- (3) 直下の無資格者による販売に対するインセンティブ ---
    referrals.reject(&:bonus_eligible?).each do |child|
      child_purchase_items = PurchaseItem.joins(:purchase)
                                        .where(purchases: { user_id: child.id, purchased_at: from_date..to_date })
                                        .includes(:product, purchase: :user)
      
      child_purchase_items.each do |item|
        purchase_date = item.purchase.purchased_at
        my_level_at_purchase = level_at(purchase_date)
        product = item.product
        base_price = product.base_price
        my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
        diff = base_price - my_price
        
        if diff.positive?
          item_bonus = diff * item.quantity
          details[:unqualified_sales] += item_bonus
          details[:purchase_count] += 1
        end
      end
    end

    total_incentive = details[:own_sales] + details[:descendant_sales] + details[:unqualified_sales]

    {
      total: total_incentive,
      details: details,
      month: month_str,
      user_name: display_name,
      current_level: level&.name
    }
  end

  # 指定月の総インセンティブを履歴ベースで計算（シンプル版）
  def monthly_total_incentive(month_str = nil)
    monthly_incentive_with_details(month_str)[:total]
  end

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

    total_bonus = 0
    purchase_user = purchase.user

    # 各購入アイテムに対してボーナスを計算
    purchase.purchase_items.each do |item|
      product = item.product
      quantity = item.quantity

      # 自分の販売か？
      if purchase_user == self
        base_price = product.base_price
        my_price = product.product_prices.find_by(level_id: level_id)&.price || 0
        total_bonus += (base_price - my_price) * quantity
        next
      end

      # 自分の直下の無資格者の販売か？
      if referrals.include?(purchase_user) && !purchase_user.bonus_eligible?
        base_price = product.base_price
        my_price = product.product_prices.find_by(level_id: level_id)&.price || 0
        diff = base_price - my_price
        total_bonus += diff * quantity if diff.positive?
        next
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
            total_bonus += diff * quantity if diff.positive?
            break
          end
        end
      end
    end

    total_bonus
  end

  # インセンティブ単価を計算（履歴ベース）
  def incentive_unit_price_for_item(purchase_item)
    return 0 unless bonus_eligible?

    purchase = purchase_item.purchase
    purchase_user = purchase.user
    product = purchase_item.product
    purchase_date = purchase.purchased_at

    # 購入時点での自分のレベルを取得
    my_level_at_purchase = level_at(purchase_date)
    my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
    
    # 自分の販売の場合：基本単価 - 購入時点での自分の購入単価
    if purchase_user == self
      base_price = product.base_price
      incentive_unit = base_price - my_price
    else
      # 他人の販売の場合：階層差額による計算
      # 購入者の購入時点でのレベルを取得
      purchase_user_level = purchase_user.level_at(purchase_date)
      purchase_user_price = product.product_prices.find_by(level_id: purchase_user_level.id)&.price || 0
      
      # 階層差額：購入者の価格 - 自分の価格
      incentive_unit = purchase_user_price - my_price
    end
    
    # 負の値の場合は0を返す
    incentive_unit > 0 ? incentive_unit : 0
  end

  # 個別のpurchase_itemに対するボーナスを計算
  def bonus_for_purchase_item(purchase_item)
    return 0 unless bonus_eligible?

    # インセンティブ単価 × 数量 = インセンティブ
    incentive_unit = incentive_unit_price_for_item(purchase_item)
    return incentive_unit * purchase_item.quantity
  end

  def bonus_in_period(start_date, end_date)
    return 0 unless bonus_eligible?

    range = start_date..end_date
    total_bonus = 0

    # --- (1) 自分の販売に対するボーナス ---
    my_purchase_items = PurchaseItem.joins(:purchase)
                                   .where(purchases: { user_id: id, purchased_at: range })
                                   .includes(:product, purchase: :user)

    my_purchase_items.each do |item|
      bonus = bonus_for_purchase_item(item)
      total_bonus += bonus
    end

    # --- (2) 子孫の販売に対するボーナス（階層差額） ---
    descendant_user_ids = descendant_ids.reject { |uid| uid == id }
    
    if descendant_user_ids.any?
      descendant_purchase_items = PurchaseItem.joins(:purchase)
                                             .where(purchases: { user_id: descendant_user_ids, purchased_at: range })
                                             .includes(:product, purchase: :user)

      descendant_purchase_items.each do |item|
        purchase = item.purchase
        purchase_user_level = purchase.user.level_at(purchase.purchased_at)
        my_level_at_purchase = level_at(purchase.purchased_at)
        
        product = item.product
        purchase_user_price = product.product_prices.find_by(level_id: purchase_user_level.id)&.price || 0
        my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
        
        if purchase_user_price > my_price
          diff = purchase_user_price - my_price
          total_bonus += diff * item.quantity
        end
      end
    end

    # --- (3) 直下の無資格者による販売に対するボーナス ---
    # 既に子孫として計算されたユーザーを除外
    descendant_user_ids_set = Set.new(descendant_ids)
    
    referrals.reject(&:bonus_eligible?).each do |child|
      # 既に子孫として計算済みの場合はスキップ
      next if descendant_user_ids_set.include?(child.id)
      
      child_purchase_items = PurchaseItem.joins(:purchase)
                                        .where(purchases: { user_id: child.id, purchased_at: range })
                                        .includes(:product, purchase: :user)
      
      child_purchase_items.each do |item|
        purchase_date = item.purchase.purchased_at
        my_level_at_purchase = level_at(purchase_date)
        product = item.product
        base_price = product.base_price
        my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
        diff = base_price - my_price
        total_bonus += diff * item.quantity if diff.positive?
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

  # 指定日時でのレベルを取得
  def level_at(datetime)
    history = user_level_histories.effective_at(datetime).order(:effective_from).last
    history&.level || level
  end

  # 指定日時での商品価格を取得
  def product_price_at(product, datetime)
    level_at_time = level_at(datetime)
    product.product_prices.find_by(level_id: level_at_time.id)&.price || 0
  end

  # レベル変更時の履歴更新
  def update_level_history(new_level_id, change_reason, changed_by_user, ip_address = nil)
    return false if level_id == new_level_id

    transaction do
      # 現在の履歴を終了
      current_history = user_level_histories.current.first
      if current_history
        current_history.update!(effective_to: Time.current)
      end

      # 新しい履歴を作成
      user_level_histories.create!(
        level_id: new_level_id,
        previous_level_id: level_id,
        effective_from: Time.current,
        change_reason: change_reason,
        changed_by: changed_by_user,
        ip_address: ip_address
      )

      # ユーザーの現在レベルを更新
      update!(level_id: new_level_id)
    end

    true
  rescue => e
    Rails.logger.error "Level history update failed: #{e.message}"
    false
    false
  end

  private

  def check_level_hierarchy
    return unless referrer&.level&.value && level&.value
    if level.value < referrer.level.value
      errors.add(:level, "紹介者より上のレベルには設定できません")
    end
  end
end
