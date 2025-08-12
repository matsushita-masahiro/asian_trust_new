class Purchase < ApplicationRecord
  # 🔗 関連
  belongs_to :user      # 購入を仲介した代理店
  belongs_to :customer
  has_many :purchase_items, dependent: :destroy
  has_many :products, through: :purchase_items

  # ネストした属性を受け入れる
  accepts_nested_attributes_for :purchase_items, allow_destroy: true

  # 💰 合計金額（全アイテムの合計）
  def total_price
    purchase_items.sum(&:total_price)
  end

  # 商品数の合計
  def total_quantity
    purchase_items.sum(:quantity)
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




end
