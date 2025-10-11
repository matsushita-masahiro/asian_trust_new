class PurchaseInvoice < ApplicationRecord
  belongs_to :purchase
  
  # Active Storage for PDF files
  has_one_attached :pdf_file
  has_one_attached :receipt_file
  
  # バリデーション
  validates :invoice_number, presence: true, uniqueness: true
  validates :invoice_date, presence: true
  validates :due_date, presence: true
  validates :total_amount, presence: true, numericality: { greater_than: 0 }
  
  # ステータス定数
  DRAFT = 0           # 下書き
  SENT = 1            # 送付済み
  PAID = 2            # 支払い完了
  RECEIPT_REQUESTED = 3  # 領収書発行依頼済み
  RECEIPT_SENT = 4       # 領収書発行完了
  
  # ステータスのバリデーション
  validates :status, inclusion: { in: [DRAFT, SENT, PAID, RECEIPT_REQUESTED, RECEIPT_SENT] }
  
  # ステータス判定メソッド
  def draft?
    status == DRAFT
  end
  
  def sent?
    status == SENT
  end
  
  def paid?
    status == PAID
  end
  
  def receipt_requested?
    status == RECEIPT_REQUESTED
  end
  
  def receipt_sent?
    status == RECEIPT_SENT
  end
  
  # ステータス変更メソッド
  def draft!
    update!(status: DRAFT)
  end
  
  def sent!
    update!(status: SENT, sent_at: Time.current)
  end
  
  def paid!
    update!(status: PAID, confirmed_at: Time.current)
  end
  
  def receipt_requested!
    update!(status: RECEIPT_REQUESTED, receipt_requested_at: Time.current)
  end
  
  def receipt_sent!
    update!(status: RECEIPT_SENT, receipt_sent_at: Time.current)
  end
  
  # スコープ
  scope :draft, -> { where(status: DRAFT) }
  scope :sent, -> { where(status: SENT) }
  scope :paid, -> { where(status: PAID) }
  scope :receipt_requested, -> { where(status: RECEIPT_REQUESTED) }
  scope :receipt_sent, -> { where(status: RECEIPT_SENT) }
  
  # ステータス表示名を取得
  def status_display_name
    case status
    when DRAFT then '下書き'
    when SENT then '送付済み'
    when PAID then '支払い完了'
    when RECEIPT_REQUESTED then '領収書発行依頼済み'
    when RECEIPT_SENT then '領収書発行完了'
    else '不明'
    end
  end
  
  # 請求書番号の自動生成
  def self.generate_invoice_number
    date_prefix = Date.current.strftime("%Y%m")
    last_invoice = where("invoice_number LIKE ?", "PI#{date_prefix}%").order(:invoice_number).last
    
    if last_invoice
      last_number = last_invoice.invoice_number.gsub("PI#{date_prefix}", "").to_i
      next_number = last_number + 1
    else
      next_number = 1
    end
    
    "PI#{date_prefix}#{format('%04d', next_number)}"
  end
  
  # 購入者情報の委譲
  delegate :buyer, to: :purchase
  delegate :user, to: :purchase  # 販売者
  delegate :purchased_at, to: :purchase
  
  # 購入明細の委譲
  delegate :purchase_items, to: :purchase
  delegate :total_price, to: :purchase
end
