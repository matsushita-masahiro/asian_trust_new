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
  
  # コールバック：作成時にステータスをSENTに設定
  before_validation :set_initial_status, on: :create
  
  # ステータス定数
  DRAFT = 0           # 下書き
  SENT = 1            # 送付済み
  PAYMENT_CONFIRMATION_REQUEST = 2  # 支払確認依頼
  PAID = 3            # 支払い完了
  RECEIPT_REQUESTED = 4  # 領収書発行依頼済み
  RECEIPT_SENT = 5       # 領収書発行完了
  
  # ステータスのバリデーション
  validates :status, inclusion: { in: [DRAFT, SENT, PAYMENT_CONFIRMATION_REQUEST, PAID, RECEIPT_REQUESTED, RECEIPT_SENT] }
  
  # ステータス判定メソッド
  def draft?
    status == DRAFT
  end
  
  def sent?
    status == SENT
  end
  
  def payment_confirmation_request?
    status == PAYMENT_CONFIRMATION_REQUEST
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
  
  def payment_confirmation_request!
    update!(status: PAYMENT_CONFIRMATION_REQUEST)
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
  scope :payment_confirmation_request, -> { where(status: PAYMENT_CONFIRMATION_REQUEST) }
  scope :paid, -> { where(status: PAID) }
  scope :receipt_requested, -> { where(status: RECEIPT_REQUESTED) }
  scope :receipt_sent, -> { where(status: RECEIPT_SENT) }
  
  # ステータス表示名を取得
  def status_display_name
    case status
    when DRAFT then '支払確認前'
    when SENT then '送付済み'
    when PAYMENT_CONFIRMATION_REQUEST then '支払確認依頼'
    when PAID then '支払い完了'
    when RECEIPT_REQUESTED then '領収書発行依頼済み'
    when RECEIPT_SENT then '領収書発行完了'
    else '不明'
    end
  end
  
  # 請求書番号の自動生成
  def self.generate_invoice_number
    # 年下2桁を取得（例：2025年 → 25）
    year_suffix = Date.current.strftime("%y")
    
    # 同じ年の請求書の中で最大の連番を取得
    last_invoice = where("invoice_number LIKE ?", "PI#{year_suffix}%").order(:invoice_number).last
    
    if last_invoice
      # 既存の請求書番号から連番部分を抽出（PI25001 → 001）
      last_number = last_invoice.invoice_number.gsub("PI#{year_suffix}", "").to_i
      next_number = last_number + 1
    else
      next_number = 1
    end
    
    # PI + 年下2桁 + 3桁連番（例：PI25001）
    "PI#{year_suffix}#{format('%03d', next_number)}"
  end
  
  # 購入者情報の委譲
  delegate :user, to: :purchase  # 購入者
  delegate :purchased_at, to: :purchase
  
  # 購入明細の委譲
  delegate :purchase_items, to: :purchase
  delegate :total_price, to: :purchase
  
  # クリニック予約関連メソッド
  def has_clinic_delivery?
    purchase.delivery_informations.where(delivery_type: ['clinic', 'multiple']).exists?
  end
  
  def clinic_reservation
    purchase.clinic_reservation
  end
  
  def clinic_reservation_required?
    has_clinic_delivery? && purchase.paid?
  end
  
  def clinic_reservation_status
    if !has_clinic_delivery?
      :not_required
    elsif !purchase.paid?
      :payment_required
    elsif clinic_reservation.present?
      :reserved
    else
      :not_reserved
    end
  end
  
  def clinic_reservation_status_text
    case clinic_reservation_status
    when :not_required
      "予約不要"
    when :payment_required
      "入金後予約可能"
    when :reserved
      "予約済み"
    when :not_reserved
      "未予約"
    end
  end

  private

  def set_initial_status
    self.status = SENT if status.nil?
    self.sent_at = Time.current if sent_at.nil?
  end
end
