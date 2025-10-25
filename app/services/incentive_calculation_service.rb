# インセンティブ計算サービス
# 月の途中の任意の日付時点でのインセンティブ計算と詳細明細を提供
class IncentiveCalculationService
  attr_reader :user, :start_date, :end_date, :date_range_info

  def initialize(user, start_date = nil, end_date = nil)
    @user = user
    
    # 日付が指定されていない場合は現在月の月初から今日まで
    if start_date.nil? || end_date.nil?
      range_info = DateRangeService.current_month_range
      @start_date = range_info[:start_date]
      @end_date = range_info[:end_date]
      @date_range_info = range_info
    else
      @start_date = start_date
      @end_date = end_date
      @date_range_info = DateRangeService.custom_range(start_date, end_date)
    end
  end

  # 月初から指定日までの計算用コンストラクタ
  def self.for_month_to_date(user, target_date)
    range_info = DateRangeService.month_to_date_range(target_date)
    service = new(user, range_info[:start_date], range_info[:end_date])
    service.instance_variable_set(:@date_range_info, range_info)
    service
  end

  # 前月の計算用コンストラクタ
  def self.for_previous_month(user)
    range_info = DateRangeService.previous_month_range
    service = new(user, range_info[:start_date], range_info[:end_date])
    service.instance_variable_set(:@date_range_info, range_info)
    service
  end

  # 詳細インセンティブ計算のメインメソッド
  def calculate_detailed_incentives
    return { total: 0, details: {}, error: 'インセンティブ受領権利がありません' } unless user.bonus_eligible?

    details = {
      own_sales: 0,           # 自分の購入によるインセンティブ
      descendant_sales: 0,    # 子孫の購入による階層差額インセンティブ
      unqualified_sales: 0,   # 無資格者の購入によるインセンティブ
      purchase_count: 0,      # 対象購入件数
      level_changes: [],      # 期間中のレベル変更履歴
      purchase_details: []    # 購入アイテム詳細
    }

    # レベル変更履歴を取得
    details[:level_changes] = get_level_changes

    # 各分類のインセンティブを計算
    details[:own_sales] = calculate_own_sales_incentive(details)
    details[:descendant_sales] = calculate_descendant_incentive(details)

    total_incentive = details[:own_sales] + details[:descendant_sales]

    {
      total: total_incentive,
      details: details,
      period: date_range_info[:display_range],
      period_days: date_range_info[:days_count],
      user_name: user.display_name,
      current_level: user.level&.name,
      calculation_date: Time.current
    }
  end

  # 階層別売上計算
  def calculate_hierarchy_sales
    return {} unless user.bonus_eligible?

    hierarchy_data = {}

    # 直下位ユーザーの売上を計算
    user.referrals.each do |referral|
      # 本人売上 + 下位売上の合計を計算
      own_sales = calculate_user_sales(referral)[:total]
      descendant_sales = calculate_descendant_sales(referral)
      total_sales = own_sales + descendant_sales
      
      # インセンティブ受給資格がないユーザーのインセンティブは0
      incentive_amount = referral.bonus_eligible? ? calculate_incentive_from_user(referral) : 0
      
      hierarchy_data[referral.id] = {
        user: referral,
        user_name: referral.display_name,
        level: referral.level&.name,
        sales_total: total_sales,
        purchase_count: own_sales > 0 ? 1 : 0, # 簡略化
        incentive_amount: incentive_amount,
        has_descendants: referral.referrals.any?
      }
    end

    hierarchy_data
  end

  # 特定ユーザーの下位売上を計算
  def calculate_descendant_sales(target_user)
    descendant_ids = target_user.descendant_ids
    return 0 if descendant_ids.empty?

    PurchaseItem.joins(:purchase)
                .where(purchases: { user_id: descendant_ids, purchased_at: start_date..end_date })
                .sum('purchase_items.seller_price * purchase_items.quantity')
  end

  # 特定ユーザーの売上データを計算
  def calculate_user_sales(target_user)
    purchase_items = PurchaseItem.joins(:purchase)
                                .where(purchases: { user_id: target_user.id, purchased_at: start_date..end_date })
                                .includes(:product, purchase: :user)

    total = purchase_items.sum('purchase_items.seller_price * purchase_items.quantity')
    count = purchase_items.count

    {
      total: total,
      count: count,
      items: purchase_items
    }
  end

  private

  # 自分の購入によるインセンティブを計算
  def calculate_own_sales_incentive(details)
    total_incentive = 0

    my_purchase_items = PurchaseItem.joins(:purchase)
                                   .where(purchases: { user_id: user.id, purchased_at: start_date..end_date })
                                   .includes(:product, purchase: :user)

    my_purchase_items.each do |item|
      product = item.product
      
      if product.category == 'wott'
        # WOTT商品の場合：自己購入でのみインセンティブ発生
        if user.has_wott_level?
          wott_level = user.wott_level
          incentive_record = product.product_prices.find_by(wott_level: wott_level)
          if incentive_record&.price
            incentive_unit = (product.base_price || 0) - incentive_record.price
            item_incentive = incentive_unit > 0 ? incentive_unit * item.quantity : 0
          else
            incentive_unit = 0
            item_incentive = 0
          end
        else
          incentive_unit = 0
          item_incentive = 0
        end
      else
        # 通常商品の場合：従来の計算方式（自己購入インセンティブは廃止されているため0）
        incentive_unit = 0
        item_incentive = 0
      end

      if item_incentive > 0
        total_incentive += item_incentive
        details[:purchase_count] += 1
        
        # 詳細情報を追加
        details[:purchase_details] << create_purchase_detail(item, 'own_sales', incentive_unit, item_incentive)
      end
    end

    total_incentive
  end

  # 子孫の購入による階層差額インセンティブを計算
  def calculate_descendant_incentive(details)
    total_incentive = 0
    
    # すべての子孫を対象とする（お客様の購入も含む）
    descendant_user_ids = user.descendant_ids.reject { |uid| uid == user.id }
    
    return total_incentive if descendant_user_ids.empty?

    descendant_purchase_items = PurchaseItem.joins(:purchase)
                                           .where(purchases: { user_id: descendant_user_ids, purchased_at: start_date..end_date })
                                           .includes(:product, purchase: :user)

    descendant_purchase_items.each do |item|
      purchase = item.purchase
      purchase_date = purchase.purchased_at
      purchase_user = purchase.user
      product = item.product
      
      if product.category == 'wott'
        # WOTT商品の場合：他人の購入ではインセンティブなし（自己購入のみ）
        next
      else
        # 通常商品の場合：従来の階層差額計算
        my_level_at_purchase = user.level_at(purchase_date)
        
        # 購入者から自分までの経路を確認
        path_to_me = purchase_user.path_to_ancestor(user)
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
          incentive_unit = eligible_user_price - my_price
          item_incentive = incentive_unit * item.quantity
          total_incentive += item_incentive
          details[:purchase_count] += 1
          
          # 詳細情報を追加（実際に使用された価格を渡す）
          details[:purchase_details] << create_purchase_detail(item, 'descendant_sales', incentive_unit, item_incentive, eligible_user_price)
        end
      end
    end

    total_incentive
  end



  # 特定ユーザーからのインセンティブを計算（そのユーザーの全体インセンティブを取得）
  def calculate_incentive_from_user(target_user)
    return 0 unless target_user.bonus_eligible?

    # 対象ユーザーの月間インセンティブ合計を取得
    month_string = start_date.strftime("%Y-%m")
    incentive_data = target_user.monthly_incentive_with_details(month_string)
    
    incentive_data[:total] || 0
  end

  # レベル変更履歴を取得
  def get_level_changes
    level_histories = user.user_level_histories
                         .where(effective_from: start_date..end_date)
                         .includes(:level, :previous_level, :changed_by)
                         .order(:effective_from)

    level_histories.map do |history|
      {
        date: history.effective_from,
        from_level: history.previous_level&.name,
        to_level: history.level.name,
        reason: history.change_reason,
        changed_by: history.changed_by&.name
      }
    end
  end

  # 購入詳細情報を作成
  def create_purchase_detail(item, category, incentive_unit, item_incentive, actual_price = nil)
    purchase = item.purchase
    product = item.product
    
    # 田中美咲（user）の直下のユーザーを特定
    direct_referral = find_direct_referral_for_purchase(purchase.user)
    
    # 直下ユーザーの単価を取得
    direct_referral_price = if direct_referral
      direct_referral_level = direct_referral.level_at(purchase.purchased_at)
      product.product_prices.find_by(level_id: direct_referral_level.id)&.price || 0
    else
      0
    end
    
    {
      category: category,
      purchase_id: purchase.id,
      purchaser_display_name: purchase.user.display_name,
      direct_referral_display_name: direct_referral&.display_name,
      direct_referral_price: direct_referral_price,
      product_name: product.display_name,
      purchase_date: purchase.purchased_at,
      quantity: item.quantity,
      unit_price: item.unit_price,
      incentive_unit_price: incentive_unit,
      total_incentive: item_incentive,
      calculation_details: build_calculation_details(item, incentive_unit, actual_price)
    }
  end

  # 田中美咲の直下のユーザーを特定
  def find_direct_referral_for_purchase(purchase_user)
    # 購入者から田中美咲（user）までの経路を取得
    path_to_me = purchase_user.path_to_ancestor(user)
    return nil unless path_to_me && path_to_me.length >= 2
    
    # 経路の2番目のユーザーが田中美咲の直下のユーザー
    # path_to_me = [田中美咲, 鈴木愛美, 中村結衣] の場合、鈴木愛美が直下
    path_to_me[1]
  end

  # 計算詳細を構築
  def build_calculation_details(item, incentive_unit, actual_price = nil)
    purchase = item.purchase
    product = item.product
    purchase_date = purchase.purchased_at
    
    purchaser_level = purchase.user.level_at(purchase_date)
    my_level = user.level_at(purchase_date)
    
    base_price = product.base_price
    # 実際の購入価格（seller_price）を使用
    actual_purchaser_price = item.seller_price || 0
    
    # WOTT商品の場合は特別処理
    if product.category == 'wott'
      # WOTT商品の場合：購入者のWOTTレベルを表示し、WOTT価格を使用
      purchaser_wott_level = purchase.user.wott_level
      my_wott_level = user.wott_level
      
      # WOTT価格を取得
      my_wott_price = product.product_prices.find_by(wott_level: my_wott_level)&.price || 0
      
      {
        base_price: base_price,
        purchaser_price: actual_purchaser_price,
        my_price: my_wott_price,
        purchaser_level: purchaser_wott_level&.name || '未設定',
        my_level: my_wott_level&.name || '未設定',
        calculation_formula: "#{base_price} - #{my_wott_price} = #{incentive_unit}"
      }
    else
      # 通常商品の場合：従来通りの処理
      my_price = product.product_prices.find_by(level_id: my_level.id)&.price || 0
      
      # 実際に使用された価格がある場合はそれを使用、なければ実際の購入価格を使用
      effective_price = actual_price || actual_purchaser_price
      
      {
        base_price: base_price,
        purchaser_price: actual_purchaser_price,
        my_price: my_price,
        purchaser_level: purchaser_level&.name,
        my_level: my_level&.name,
        calculation_formula: "#{effective_price} - #{my_price} = #{incentive_unit}"
      }
    end
  end

  # 日付範囲の妥当性チェック
  def self.validate_date_range(start_date, end_date)
    DateRangeService.valid_range?(start_date, end_date)
  end

  # 月文字列から期間を作成
  def self.from_month_string(user, month_string)
    unless DateRangeService.validate_month_string(month_string)
      raise DateRangeService::InvalidDateError, "無効な月形式です: #{month_string}"
    end
    
    date = Date.strptime(month_string, "%Y-%m")
    last_day = date.end_of_month
    today = Time.current.in_time_zone("Asia/Tokyo").to_date
    
    # 現在月の場合は今日まで、過去月の場合は月末まで
    target_date = date.month == today.month && date.year == today.year ? today : last_day
    
    for_month_to_date(user, target_date)
  end
end