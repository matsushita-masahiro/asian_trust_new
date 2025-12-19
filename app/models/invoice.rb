class Invoice < ApplicationRecord
  belongs_to :user
  belongs_to :invoice_recipient
  
  # Active Storage for PDF files
  has_one_attached :pdf_file
  has_one_attached :receipt_file
  
  # コールバック
  before_create :set_invoice_number
  
  # バリデーション
  validates :target_month, presence: true, format: { with: /\A\d{4}-\d{2}\z/, message: "は YYYY-MM 形式で入力してください" }, allow_blank: false

  # ステータス定数（新）
  INITIAL = 0     # 初期状態
  DRAFT = 1       # 下書き
  SENT = 2        # 送付済み
  CONFIRMED = 3   # 振込確認済み
  RECEIPT_REQUESTED = 4  # 領収書発行依頼済み
  RECEIPT_SENT = 5      # 領収書発行完了
  
  
  # 旧ステータス定数（互換性のため一時的に保持）
  OLD_DRAFT = 0
  OLD_SENT = 1
  OLD_CONFIRMED = 2
  
  # ステータスのバリデーション
  validates :status, inclusion: { in: [INITIAL, DRAFT, SENT, CONFIRMED, RECEIPT_REQUESTED, RECEIPT_SENT] }
  
  # ステータス判定メソッド
  def initial?
    status == INITIAL
  end
  
  def draft?
    status == DRAFT
  end
  
  def sent?
    status == SENT
  end
  
  def confirmed?
    status == CONFIRMED
  end
  
  def receipt_requested?
    status == RECEIPT_REQUESTED
  end
  
  def receipt_sent?
    status == RECEIPT_SENT
  end
  
  # ステータス変更メソッド
  def initial!
    update!(status: INITIAL)
  end
  
  def draft!
    update!(status: DRAFT)
  end
  
  def sent!
    update!(status: SENT)
  end
  
  def confirmed!
    update!(status: CONFIRMED)
  end
  
  def receipt_requested!
    update!(status: RECEIPT_REQUESTED)
  end
  
  def receipt_sent!
    update!(status: RECEIPT_SENT, sent_at: Time.current)
  end
  
  # スコープ
  scope :initial, -> { where(status: INITIAL) }
  scope :draft, -> { where(status: DRAFT) }
  scope :sent, -> { where(status: SENT) }
  scope :confirmed, -> { where(status: CONFIRMED) }
  scope :receipt_requested, -> { where(status: RECEIPT_REQUESTED) }
  scope :receipt_sent, -> { where(status: RECEIPT_SENT) }
  
  # ステータス名を取得
  def status_name
    case status
    when INITIAL then 'initial'
    when DRAFT then 'draft'
    when SENT then 'sent'
    when CONFIRMED then 'confirmed'
    when RECEIPT_REQUESTED then 'receipt_requested'
    when RECEIPT_SENT then 'receipt_sent'
    else 'unknown'
    end
  end
  
  # ステータス表示名を取得
  def status_display_name
    case status
    when INITIAL then '初期状態'
    when DRAFT then '下書き'
    when SENT then '送付済み'
    when CONFIRMED then '振込確認済み'
    when RECEIPT_REQUESTED then '領収書発行依頼済み'
    when RECEIPT_SENT then '領収書発行完了'
    else '不明'
    end
  end
  
  # 対象年月の表示名を取得
  def target_month_display
    return '' if target_month.blank?
    Date.strptime(target_month, "%Y-%m").strftime("%Y/%m")
  end
  
  # 対象年月の売上データを取得
  def target_month_sales
    return 0 if target_month.blank?
    user.own_monthly_sales_total(target_month)
  end
  
  # 対象年月のボーナスデータを取得
  def target_month_bonus
    return 0 if target_month.blank?
    user.bonus_in_month(target_month)
  end
  
  # インセンティブ請求書番号の生成（重複回避のため連番付き）
  def self.generate_invoice_number(user_id, target_month)
    return nil if user_id.blank? || target_month.blank?
    
    # target_monthから年月を取得（例：2025-07 → 2507）
    year_month = Date.strptime(target_month, "%Y-%m").strftime("%y%m")
    
    # 基本パターン：INV-INC + user_id + 年月
    base_pattern = "INV-INC#{user_id}#{year_month}"
    
    # 同じパターンで始まる請求書番号を検索
    existing_invoices = where("invoice_number LIKE ?", "#{base_pattern}%")
                       .order(:invoice_number)
    
    if existing_invoices.any?
      # 最後の連番を取得
      last_invoice = existing_invoices.last
      last_number = last_invoice.invoice_number.gsub(base_pattern, "").to_i
      next_number = last_number + 1
    else
      next_number = 1
    end
    
    "#{base_pattern}#{next_number}"
  end
  
  # 請求書番号を自動設定
  def set_invoice_number
    if invoice_number.blank? && user_id.present? && target_month.present?
      self.invoice_number = self.class.generate_invoice_number(user_id, target_month)
    end
  end
  
end