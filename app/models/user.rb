require 'set'

class User < ApplicationRecord
  # Devise（認証機能）- registrableは使わずカスタム登録機能を実装
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable,
         :trackable, :lockable

  # 紹介者との関係
  belongs_to :referrer, class_name: 'User', foreign_key: 'referred_by_id', optional: true
  has_many   :referrals, class_name: 'User', foreign_key: 'referred_by_id'
  has_many   :referred_users, class_name: 'User', foreign_key: 'referred_by_id'
  
  # 紹介招待システム
  has_many :referral_invitations, foreign_key: 'referrer_id', dependent: :destroy
  has_one :received_invitation, class_name: 'ReferralInvitation', foreign_key: 'invited_user_id'
  # invoice関連
  has_many :invoices
  has_one  :invoice_recipient
  has_one  :invoice_base

  # 住所関連
  has_many :addresses, dependent: :destroy
  has_one :registration_address, -> { where(address_type: 'registration') }, class_name: 'Address'
  has_one :shipping_address, -> { where(address_type: 'shipping') }, class_name: 'Address'

  # 会員レベル
  belongs_to :level
  belongs_to :wott_level, optional: true

  # 紹介トークン
  before_save :generate_referral_token, if: -> { referral_token.blank? }

  # バリデーション
  validates :phone, presence: true
  validates :phone, format: { with: /\A[\d\-\(\)\+\s]+\z/, message: "は有効な電話番号を入力してください" }, allow_blank: true
  validates :phone, uniqueness: { message: "は既に使用されています" }, allow_blank: true
  
  # 購入関連のリレーション
  has_many :purchases, class_name: 'Purchase', foreign_key: 'user_id'  # 自分の購入
  has_many :clinic_reservations, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :inquiries, dependent: :destroy
  
  # カート機能
  has_one :cart, dependent: :destroy
  
  def ensure_cart
    cart || create_cart
  end
  
  # WOTTレベル昇格申請
  has_many :wott_level_upgrade_requests, dependent: :destroy
  
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

  BONUS_ELIGIBLE_LEVELS = %w[アジアビジネストラスト 総代理店 代理店 アドバイザー サポーター].freeze

  # コールバック
  before_create :generate_referral_token

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

  # お客様レベルかどうかを判定
  def customer?
    level&.customer?
  end

  # アジアビジネストラストかどうかを判定
  def company?
    level&.company?
  end

  def display_name
    name.present? ? "#{name} (#{level_label})" : level_label
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

  def all_descendants
    descendants
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
    # 新しい構造：purchase_itemsから合計を計算（seller_priceベース）
    Purchase.joins(:purchase_items)
            .where(user: self, status: 'paid')
            .in_month_tokyo(month_str)
            .sum('purchase_items.seller_price * purchase_items.quantity')
  end
  
  def direct_referees_monthly_sales_total(month_str)
    referred_users.sum do |user|
      user.own_monthly_sales_total(month_str)
    end
  end
  
  def all_descendants_monthly_sales_total(month_str)
    Purchase.joins(:purchase_items)
            .where(user_id: descendant_ids, status: 'paid')
            .in_month_tokyo(month_str)
            .sum('purchase_items.seller_price * purchase_items.quantity')
  end
  
  def total_sales_with_descendants(month_str)
    own_monthly_sales_total(month_str) + all_descendants_monthly_sales_total(month_str)
  end

  # 自分の購入合計
  def own_purchase_total(month_str = nil)
    scope = purchases.joins(:purchase_items)
    
    if month_str
      scope = scope.in_month_tokyo(month_str)
    end
    
    scope.sum('purchase_items.unit_price * purchase_items.quantity')
  end

  # 販売合計（現在のシステムでは使用しない - 自己購入のみ）
  def sales_total(month_str = nil)
    # 現在のシステムでは販売者と購入者が同じなので、常に0を返す
    return 0
    
    if month_str
      scope = scope.in_month_tokyo(month_str)
    end
    
    scope.sum('purchase_items.unit_price * purchase_items.quantity')
  end


  def bonus_eligible?
    BONUS_ELIGIBLE_LEVELS.include?(level&.name)
  end
  
  # プロモートチーム（WOTTインセンティブ対象）かどうか
  def is_promote_team?
    wott_level&.name.in?(['総代理店', '代理店', 'サポーター'])
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
      sl: 0,                  # 幹細胞培養上清液のインセンティブ
      wott: 0,                # WOTTのインセンティブ
      ms: 0,                  # MANNERSOUNDのインセンティブ
      ag: 0,                  # エアガンのインセンティブ
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
    # 通常商品の自己購入インセンティブは廃止
    # ただし、WOTT商品の自己購入インセンティブは有効
    my_purchase_items = PurchaseItem.joins(:purchase)
                                   .where(purchases: { user_id: id, purchased_at: from_date..to_date, status: ['paid', 'reserved'] })
                                   .includes(:product, purchase: :user)

    my_purchase_items.each do |item|
      product = item.product
      category = product.respond_to?(:category) ? product.category : 'sl'
      
      # WOTT商品の場合
      if category == 'wott'
        # プロモートチーム（総代理店、代理店、サポーター）のみインセンティブ対象
        purchase_date = item.purchase.purchased_at
        wott_level_at_purchase = wott_level_at(purchase_date)
        
        if wott_level_at_purchase && ['総代理店', '代理店', 'サポーター'].include?(wott_level_at_purchase.name)
          incentive_record = product.product_prices.find_by(wott_level: wott_level_at_purchase)
          if incentive_record&.incentive_rate && product.base_price
            # base_price × incentive_rate でインセンティブ計算
            incentive_unit = (product.base_price * incentive_record.incentive_rate).to_i
            item_incentive = incentive_unit * item.quantity
            details[:wott] += item_incentive
            details[:purchase_count] += 1 if item_incentive > 0
          end
        end
      # MANNERSOUND商品の場合
      elsif category == 'ms'
        # 会員レベル（上清液のレベル）を使用
        purchase_date = item.purchase.purchased_at
        user_level_at_purchase = level_at(purchase_date)
        
        # プロモートチーム（総代理店、代理店、アドバイザー）のみインセンティブ対象
        if user_level_at_purchase && ['総代理店', '代理店', 'アドバイザー'].include?(user_level_at_purchase.name)
          incentive_record = product.product_prices.find_by(level: user_level_at_purchase)
          if incentive_record&.incentive_rate && product.base_price
            # base_price × incentive_rate でインセンティブ計算
            incentive_unit = (product.base_price * incentive_record.incentive_rate).to_i
            item_incentive = incentive_unit * item.quantity
            details[:ms] += item_incentive
            details[:purchase_count] += 1 if item_incentive > 0
          end
        end
      end
      # 通常商品の自己購入インセンティブは廃止されているため処理しない
    end

    # --- (2) 子孫の販売に対するインセンティブ（階層差額） ---
    # すべての子孫を対象とする（お客様の購入も含む）
    descendant_user_ids = descendant_ids.reject { |uid| uid == id }
    
    if descendant_user_ids.any?
      descendant_purchase_items = PurchaseItem.joins(:purchase)
                                             .where(purchases: { user_id: descendant_user_ids, purchased_at: from_date..to_date, status: ['paid', 'reserved'] })
                                             .includes(:product, purchase: :user)

      descendant_purchase_items.each do |item|
        purchase = item.purchase
        purchase_date = purchase.purchased_at
        purchase_user = purchase.user
        product = item.product
        category = product.respond_to?(:category) ? product.category : 'sl'
        
        # WOTT商品の場合：直下位のお客様・クリニック・サロンの購入のみインセンティブ対象
        if category == 'wott'
          # 購入時点のWOTTレベルを取得
          wott_level_at_purchase = wott_level_at(purchase_date)
          
          # プロモートチームのみ対象
          if wott_level_at_purchase && ['総代理店', '代理店', 'サポーター'].include?(wott_level_at_purchase.name)
            # 直下位（referred_by_id == self.id）かつ、お客様・クリニック・サロンの場合のみ
            if purchase_user.referred_by_id == id && ['お客様', 'クリニック', 'サロン'].include?(purchase_user.level&.name)
              incentive_record = product.product_prices.find_by(wott_level: wott_level_at_purchase)
              if incentive_record&.incentive_rate && product.base_price
                # base_price × incentive_rate でインセンティブ計算
                incentive_unit = (product.base_price * incentive_record.incentive_rate).to_i
                item_incentive = incentive_unit * item.quantity
                details[:wott] += item_incentive
                details[:purchase_count] += 1 if item_incentive > 0
              end
            end
          end
          next # WOTT商品は通常の階層差額計算をスキップ
        end
        
        # MANNERSOUND商品の場合：直下位のお客様・クリニック・サロンの購入のみインセンティブ対象
        if category == 'ms'
          # 購入時点の会員レベルを取得
          user_level_at_purchase = level_at(purchase_date)
          
          # プロモートチームのみ対象
          if user_level_at_purchase && ['総代理店', '代理店', 'アドバイザー'].include?(user_level_at_purchase.name)
            # 直下位（referred_by_id == self.id）かつ、お客様・クリニック・サロンの場合のみ
            if purchase_user.referred_by_id == id && ['お客様', 'クリニック', 'サロン'].include?(purchase_user.level&.name)
              incentive_record = product.product_prices.find_by(level: user_level_at_purchase)
              if incentive_record&.incentive_rate && product.base_price
                # base_price × incentive_rate でインセンティブ計算
                incentive_unit = (product.base_price * incentive_record.incentive_rate).to_i
                item_incentive = incentive_unit * item.quantity
                details[:ms] += item_incentive
                details[:purchase_count] += 1 if item_incentive > 0
              end
            end
          end
          next # MANNERSOUND商品は通常の階層差額計算をスキップ
        end
        
        my_level_at_purchase = level_at(purchase_date)
        
        # 購入者から自分までの経路を確認
        path_to_me = purchase_user.path_to_ancestor(self)
        next unless path_to_me # 経路が見つからない場合はスキップ
        
        # 直下位ユーザーかどうかを確認（経路の長さが2の場合：自分 -> 購入者）
        if path_to_me.length == 2
          # 直下位ユーザーの場合は購入者の実際の購入価格を使用
          eligible_user_price = item.seller_price || 0
        else
          # 間接的な子孫の場合は、購入者と自分の間の経路でインセンティブ受領資格者を探す
          # 自分と購入者を除いた中間の経路のみを対象とする
          intermediate_path = path_to_me[1..-2]  # 最初（自分）と最後（購入者）を除く
          # 自分に最も近い受給資格者を探す（逆順ではなく順序通り）
          eligible_user_in_path = intermediate_path.find(&:bonus_eligible?)
          
          if eligible_user_in_path
            # 中間にインセンティブ受領資格者がいる場合、そのユーザーのレベル価格を使用
            eligible_user_level = eligible_user_in_path.level_at(purchase_date)
            eligible_user_price = product.product_prices.find_by(level_id: eligible_user_level.id)&.price || 0
          else
            # 中間にインセンティブ受領資格者がいない場合（購入者の実際の購入価格を使用）
            eligible_user_price = item.seller_price || 0
          end
        end
        
        # 自分のレベル価格を取得
        my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
        
        if eligible_user_price > my_price
          diff = eligible_user_price - my_price
          item_bonus = diff * item.quantity
          # カテゴリー毎に加算
          details[category.to_sym] += item_bonus
          details[:purchase_count] += 1
        end
      end
    end

    total_incentive = details[:sl] + details[:wott] + details[:ms] + details[:ag]

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
  
  # エイリアス：path_to_ancestorとしても使用可能
  alias_method :path_to_ancestor, :bonus_path_up_to

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

    # WOTT商品の場合は特別処理
    if product.respond_to?(:category) && product.category == 'wott'
      # 自己購入の場合
      if purchase_user == self
        # 購入時点のWOTTレベルを取得
        wott_level_at_purchase = wott_level_at(purchase_date)
        
        # プロモートチーム（総代理店、代理店、サポーター）のみインセンティブ対象
        if wott_level_at_purchase && ['総代理店', '代理店', 'サポーター'].include?(wott_level_at_purchase.name)
          incentive_record = product.product_prices.find_by(wott_level: wott_level_at_purchase)
          if incentive_record&.incentive_rate && product.base_price
            # base_price × incentive_rate でインセンティブ単価を計算
            incentive_unit = (product.base_price * incentive_record.incentive_rate).to_i
            return incentive_unit
          end
        end
        return 0
      else
        # 他人の購入の場合：直下位のお客様・クリニック・サロンのみインセンティブ対象
        wott_level_at_purchase = wott_level_at(purchase_date)
        
        if wott_level_at_purchase && ['総代理店', '代理店', 'サポーター'].include?(wott_level_at_purchase.name)
          if purchase_user.referred_by_id == id && ['お客様', 'クリニック', 'サロン'].include?(purchase_user.level&.name)
            incentive_record = product.product_prices.find_by(wott_level: wott_level_at_purchase)
            if incentive_record&.incentive_rate && product.base_price
              # base_price × incentive_rate でインセンティブ単価を計算
              incentive_unit = (product.base_price * incentive_record.incentive_rate).to_i
              return incentive_unit
            end
          end
        end
        return 0
      end
    end

    # MANNERSOUND商品の場合は特別処理
    if product.respond_to?(:category) && product.category == 'ms'
      # 自己購入の場合
      if purchase_user == self
        # 購入時点の会員レベルを取得
        user_level_at_purchase = level_at(purchase_date)
        
        # プロモートチーム（総代理店、代理店、アドバイザー）のみインセンティブ対象
        if user_level_at_purchase && ['総代理店', '代理店', 'アドバイザー'].include?(user_level_at_purchase.name)
          incentive_record = product.product_prices.find_by(level: user_level_at_purchase)
          if incentive_record&.incentive_rate && product.base_price
            # base_price × incentive_rate でインセンティブ単価を計算
            incentive_unit = (product.base_price * incentive_record.incentive_rate).to_i
            return incentive_unit
          end
        end
        return 0
      else
        # 他人の購入の場合：直下位のお客様・クリニック・サロンのみインセンティブ対象
        user_level_at_purchase = level_at(purchase_date)
        
        if user_level_at_purchase && ['総代理店', '代理店', 'アドバイザー'].include?(user_level_at_purchase.name)
          if purchase_user.referred_by_id == id && ['お客様', 'クリニック', 'サロン'].include?(purchase_user.level&.name)
            incentive_record = product.product_prices.find_by(level: user_level_at_purchase)
            if incentive_record&.incentive_rate && product.base_price
              # base_price × incentive_rate でインセンティブ単価を計算
              incentive_unit = (product.base_price * incentive_record.incentive_rate).to_i
              return incentive_unit
            end
          end
        end
        return 0
      end
    end

    # 通常商品の場合は従来の階層差額計算
    # 購入時点での自分のレベルを取得
    my_level_at_purchase = level_at(purchase_date)
    my_price = product.product_prices.find_by(level_id: my_level_at_purchase.id)&.price || 0
    
    # 自分の販売の場合：インセンティブなし（仕様変更により廃止）
    if purchase_user == self
      incentive_unit = 0
    else
      # 他人の販売の場合：階層差額による計算
      # 購入者から自分までの経路を確認
      path_to_me = purchase_user.path_to_ancestor(self)
      
      if path_to_me && path_to_me.length == 2
        # 直下位ユーザーの場合は購入者の実際の購入価格を使用
        eligible_user_price = purchase_item.seller_price || 0
      elsif path_to_me && path_to_me.length > 2
        # 間接的な子孫の場合は、中間の受給資格者を探す
        intermediate_path = path_to_me[1..-2]  # 最初（自分）と最後（購入者）を除く
        # 自分に最も近い受給資格者を探す（逆順ではなく順序通り）
        eligible_user_in_path = intermediate_path.find(&:bonus_eligible?)
        
        if eligible_user_in_path
          # 中間にインセンティブ受領資格者がいる場合、そのユーザーのレベル価格を使用
          eligible_user_level = eligible_user_in_path.level_at(purchase_date)
          eligible_user_price = product.product_prices.find_by(level_id: eligible_user_level.id)&.price || 0
        else
          # 中間にインセンティブ受領資格者がいない場合（購入者の実際の購入価格を使用）
          eligible_user_price = purchase_item.seller_price || 0
        end
      else
        # 経路がない場合は0
        eligible_user_price = 0
      end
      
      # 階層差額：有効価格 - 自分の価格
      incentive_unit = eligible_user_price - my_price
    end
    
    # 負の値の場合は0を返す
    incentive_unit > 0 ? incentive_unit : 0
  end

  # 個別のpurchase_itemに対するボーナスを計算
  def bonus_for_purchase_item(purchase_item)
    return 0 unless bonus_eligible?

    # インセンティブ単価 × 数量 = インセンティブ
    # WOTT商品の場合：自己購入のみインセンティブ発生、単価は(base_price - product_prices.price)
    # 通常商品の場合：階層差額によるインセンティブ計算
    incentive_unit = incentive_unit_price_for_item(purchase_item)
    return incentive_unit * purchase_item.quantity
  end

  def bonus_in_period(start_date, end_date)
    return 0 unless bonus_eligible?

    range = start_date..end_date
    total_bonus = 0

    # --- (1) 自分の販売に対するボーナス ---
    # 仕様変更により自己購入インセンティブは廃止

    # --- (2) 子孫の販売に対するボーナス（階層差額） ---
    # 直下の無資格者は除外（別途計算するため）
    direct_non_eligible_ids = referrals.reject(&:bonus_eligible?).pluck(:id)
    descendant_user_ids = descendant_ids.reject { |uid| uid == id || direct_non_eligible_ids.include?(uid) }
    
    if descendant_user_ids.any?
      descendant_purchase_items = PurchaseItem.joins(:purchase)
                                             .where(purchases: { user_id: descendant_user_ids, purchased_at: range, status: ['paid', 'reserved'] })
                                             .includes(:product, purchase: :user)

      descendant_purchase_items.each do |item|
        purchase = item.purchase
        purchase_user = purchase.user
        product = item.product
        
        # 購入者から上位階層への完全なチェーンを構築
        full_chain = [purchase_user]
        current = purchase_user
        while current.referred_by_id
          current = User.find(current.referred_by_id)
          full_chain << current if current.bonus_eligible?
        end
        
        # 自分が含まれている場合のみ処理
        my_index = full_chain.index(self)
        next unless my_index
        
        # 自分の直下の人との価格差のみを計算
        if my_index > 0
          lower_user = full_chain[my_index - 1]
          lower_level = lower_user.level_at(purchase.purchased_at)
          my_level = level_at(purchase.purchased_at)
          
          lower_price = product.product_prices.find_by(level_id: lower_level.id)&.price || 0
          my_price = product.product_prices.find_by(level_id: my_level.id)&.price || 0
          
          if lower_price > my_price
            diff = lower_price - my_price
            total_bonus += diff * item.quantity
          end
        end
      end
    end

    # --- (3) 直下の無資格者による販売に対するボーナス ---
    referrals.reject(&:bonus_eligible?).each do |child|
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
  
  # 指定日時でのWOTTレベルを取得
  def wott_level_at(datetime)
    history = user_level_histories.effective_at(datetime).order(:effective_from).last
    history&.wott_level || wott_level
  end

  # 指定日時での商品価格を取得
  def product_price_at(product, datetime)
    level_at_time = level_at(datetime)
    product.product_prices.find_by(level_id: level_at_time.id)&.price || 0
  end

  # レベル変更時の履歴更新（WOTTレベルも含む）
  def update_level_history(new_level_id, change_reason, changed_by_user, ip_address = nil, new_wott_level_id = nil)
    return false if level_id == new_level_id && (new_wott_level_id.nil? || wott_level_id == new_wott_level_id)

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
        wott_level_id: new_wott_level_id || wott_level_id,
        previous_wott_level_id: wott_level_id,
        effective_from: Time.current,
        change_reason: change_reason,
        changed_by: changed_by_user,
        ip_address: ip_address
      )

      # ユーザーの現在レベルを更新
      update_attributes = { level_id: new_level_id }
      update_attributes[:wott_level_id] = new_wott_level_id if new_wott_level_id
      update!(update_attributes)
    end

    true
  rescue => e
    Rails.logger.error "Level history update failed: #{e.message}"
    false
    false
  end

  # 紹介URL生成（ホスト情報が必要な場合はコントローラーで生成）
  def referral_url(host = nil)
    if host
      "#{host}/users/sign_up?ref=#{referral_token}"
    else
      "/users/sign_up?ref=#{referral_token}"
    end
  end

  # 紹介QRコード生成用のURL
  def referral_qr_url(host = nil)
    referral_url(host)
  end

  # 紹介トークンの再生成
  def regenerate_referral_token!
    update!(referral_token: generate_unique_token)
  end

  # 紹介機能が使用可能かどうか
  def can_refer?
    return false unless level&.value
    # レベル4、5、7（サロン・クリニック・お客様）は紹介不可
    # サポーター（レベル6）は紹介可能
    ![4, 5, 7].include?(level.value)
  end

  # 後方互換性メソッド
  def primary_address
    registration_address&.address || invoice_base&.address
  end

  def primary_postal_code
    registration_address&.postal_code || invoice_base&.postal_code
  end

  def full_address
    if registration_address
      "#{registration_address.postal_code} #{registration_address.address}".strip
    elsif invoice_base
      "#{invoice_base.postal_code} #{invoice_base.address}".strip
    else
      nil
    end
  end

# WOTT level helper methods

  
  def has_wott_level?
    wott_level.present?
  end
  

  def wott_level_value
    wott_level&.value
  end
  
  def display_wott_level
    has_wott_level? ? wott_level_name : '未設定'
  end 

  def wott_level_name
    wott_level&.name || '未設定'
  end

  def wott_level_symbol
    wott_level&.symbol
  end 

  # 自分と下位userのproduct.idが1,2,3,4,5の商品の総購入量（cc）を計算
  def total_purchase_volume_cc
    # 自分と下位userのIDを取得
    target_user_ids = [id] + descendant_ids
    
    # product.idが1,2,3,4,5の商品の購入アイテムを取得
    purchase_items = PurchaseItem.joins(:purchase, :product)
                                .where(purchases: { user_id: target_user_ids })
                                .where(products: { id: [1, 2, 3, 4, 5] })
                                .includes(:product)
    
    # quantity * product.unit_quantity の合計を計算
    total_cc = purchase_items.sum do |item|
      item.quantity * (item.product.unit_quantity || 0)
    end
    
    total_cc
  end

  # 登録日からの総購入量（cc）を計算（エイリアス）
  def lifetime_purchase_volume_cc
    total_purchase_volume_cc
  end

  # WOTT商品の累計購入台数を取得
  def total_wott_purchases
    purchases.joins(purchase_items: :product)
             .where(products: { category: 'wott' })
             .sum('purchase_items.quantity')
  end

  # WOTT購入台数に基づく推奨レベルを取得
  def recommended_wott_level
    total = total_wott_purchases
    if total >= 5
      Level.find_by(name: '総代理店')
    elsif total >= 1
      Level.find_by(name: '代理店')
    else
      Level.find_by(name: 'サポーター')
    end
  end

  private

  def check_level_hierarchy
    return unless referrer&.level&.value && level&.value
    if level.value < referrer.level.value
      errors.add(:level, "紹介者より上のレベルには設定できません")
    end
  end

  def generate_referral_token
    self.referral_token = generate_unique_token
  end

  def generate_unique_token
    loop do
      token = SecureRandom.urlsafe_base64(12)
      break token unless User.exists?(referral_token: token)
    end
  end

  # 紹介経由の登録かどうかを判定
  def referral_registration?
    # 紹介者が存在し、かつお客様レベル（value: 8）の場合
    referrer.present? && level&.value == 8
  end

end
