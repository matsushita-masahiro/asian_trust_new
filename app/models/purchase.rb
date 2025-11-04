class Purchase < ApplicationRecord
  # 🔗 関連
  belongs_to :user      # 購入者
  # belongs_to :customer は削除済み
  has_many :purchase_items, dependent: :destroy
  has_many :products, through: :purchase_items
  has_one :purchase_invoice, dependent: :destroy
  has_many :shipping_fees, dependent: :destroy
  has_many :delivery_informations, dependent: :destroy
  has_one :clinic_reservation, dependent: :destroy

  # ネストした属性を受け入れる
  accepts_nested_attributes_for :purchase_items, allow_destroy: true

  # 💳 支払い方法のenum
  enum :payment_type, {
    cash: 'cash',      # 銀行振込
    credit: 'credit'   # クレジットカード
  }

  # 📊 ステータスのenum
  enum :status, {
    built: 'built',       # 注文作成済み（銀行振込の場合の初期状態）
    paid: 'paid',         # 支払い完了（クレジットカードの場合の初期状態、または銀行振込確認後）
    reserved: 'reserved'  # クリニック予約完了
  }

  # コールバック：支払い方法に応じて初期ステータスを設定
  before_validation :set_initial_status, on: :create
  
  # コールバック：購入後に送料を自動設定
  after_save :set_shipping_fees, if: :should_set_shipping_fees?
  
  # コールバック：購入ステータスがpaidになった時にpurchase_invoiceのステータスも更新
  after_update :update_purchase_invoice_status, if: :saved_change_to_status?
  


  # 💰 合計金額（全アイテムの合計）- seller_priceベース
  def total_price
    purchase_items.sum(Arel.sql('quantity * seller_price'))
  end

  # 💰 定価ベースの合計金額（参考用）
  def unit_price_total
    purchase_items.sum(Arel.sql('quantity * unit_price'))
  end

  # 商品数の合計
  def total_quantity
    purchase_items.sum(:quantity)
  end

  # 💰 送料の合計
  def total_shipping_fees
    shipping_fees.sum(:amount)
  end

  # 💰 商品代金 + 送料の合計
  def total_with_shipping
    total_price + total_shipping_fees
  end

  # 💰 消費税率（10%）
  TAX_RATE = 0.10

  # 💰 消費税額を計算（商品代金 + 送料 + 事務手数料の合計に10%）
  def tax_amount
    admin_fee = purchase_invoice&.admin_fee || 0
    taxable_amount = total_price + total_shipping_fees + admin_fee
    (taxable_amount * TAX_RATE).to_i
  end

  # 💰 税込み合計金額（商品代金 + 送料 + 事務手数料 + 消費税）
  def grand_total
    admin_fee = purchase_invoice&.admin_fee || 0
    total_price + total_shipping_fees + admin_fee + tax_amount
  end

  # 送料の詳細を取得
  def shipping_fee_details
    shipping_fees.map do |fee|
      {
        type: fee.shipping_type,
        type_name: fee.shipping_type_name,
        amount: fee.amount
      }
    end
  end

  # 送料データを作成（publicメソッド）
  def create_shipping_fees!
    set_shipping_fees
  end

  # ステータス表示名を取得
  def status_display_name
    case status
    when 'built' then '入金確認前'
    when 'paid' then '支払済み'
    when 'reserved' then '予約完了'
    else status
    end
  end

  private

  def set_initial_status
    if credit?
      self.status = 'paid'
    else
      self.status = 'built'
    end
  end

  def update_purchase_invoice_status
    return unless purchase_invoice.present?
    
    if paid? && !purchase_invoice.paid?
      purchase_invoice.paid!
    end
  end

  def set_shipping_fees
    # 既に送料データが存在する場合は何もしない
    return if shipping_fees.exists?
    
    # 購入商品に基づいて送料を自動設定
    shipping_types_used = []
    
    purchase_items.includes(:product).each do |item|
      product = item.product
      shipping_type = product.shipping_type
      
      # 同じ送料タイプが既に追加されていない場合のみ追加
      unless shipping_types_used.include?(shipping_type)
        shipping_fees.create!(
          shipping_type: shipping_type,
          amount: product.shipping_fee_amount
        )
        shipping_types_used << shipping_type
      end
    end
  end

  def should_set_shipping_fees?
    # 送料データが存在せず、購入アイテムが存在する場合のみ実行
    shipping_fees.empty? && purchase_items.exists?
  end

  # 📅 今月の購入（東京時間基準）
  scope :this_month_tokyo, -> {
    Time.use_zone("Asia/Tokyo") do
      start = Time.zone.now.beginning_of_month
      ending = Time.zone.now.end_of_month.end_of_day
      where(purchased_at: start..ending)
    end
  }
  
  # app/models/purchase.rb
  scope :in_month_tokyo, ->(month_str) {
    Time.use_zone("Asia/Tokyo") do
      from = Time.zone.parse("#{month_str}-01").beginning_of_month.beginning_of_day
      to   = from.end_of_month.end_of_day
      where(purchased_at: from..to)
    end
  }

  
  
  # 月選択したとき
  scope :in_period, ->(start_date, end_date) {
    where(purchased_at: start_date..end_date)
  }
  
  # 特定ユーザーの購入履歴
  scope :bought_by, ->(user) { where(user_id: user.id) }

  # 💰 月別未入金購入分の合計金額を計算（seller_priceベース）
  def self.monthly_pending_amount(month_str)
    purchases = in_month_tokyo(month_str).where(status: 'built')
    purchases.sum { |purchase| 
      purchase.purchase_items.sum { |item| item.quantity * item.seller_price } 
    }
  end

  # 💰 月別入金済み購入分の合計金額を計算（seller_priceベース）
  def self.monthly_paid_amount(month_str)
    purchases = in_month_tokyo(month_str).where(status: ['paid', 'reserved'])
    purchases.sum { |purchase| 
      purchase.purchase_items.sum { |item| item.quantity * item.seller_price } 
    }
  end

  # 💰 月別総売上金額を計算（seller_priceベース）
  def self.monthly_total_amount(month_str)
    purchases = in_month_tokyo(month_str)
    purchases.sum { |purchase| 
      purchase.purchase_items.sum { |item| item.quantity * item.seller_price } 
    }
  end

end
