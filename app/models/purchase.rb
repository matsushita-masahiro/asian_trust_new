class Purchase < ApplicationRecord
  # 🔗 関連
  belongs_to :user      # 購入者
  # belongs_to :customer は削除済み
  has_many :purchase_items, dependent: :destroy
  has_many :products, through: :purchase_items
  has_one :purchase_invoice, dependent: :destroy

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

  private

  def set_initial_status
    if credit?
      self.status = 'paid'
    else
      self.status = 'built'
    end
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
