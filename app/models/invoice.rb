class Invoice < ApplicationRecord
  belongs_to :user
  belongs_to :invoice_recipient
  
  # バリデーション
  validates :target_month, presence: true, format: { with: /\A\d{4}-\d{2}\z/, message: "は YYYY-MM 形式で入力してください" }, allow_blank: false

  # ステータス定数（新）
  INITIAL = 0     # 初期状態
  DRAFT = 1       # 下書き
  SENT = 2        # 送付済み
  CONFIRMED = 3   # 振込確認済み
  
  # 旧ステータス定数（互換性のため一時的に保持）
  OLD_DRAFT = 0
  OLD_SENT = 1
  OLD_CONFIRMED = 2
  
  # ステータスのバリデーション
  validates :status, inclusion: { in: [INITIAL, DRAFT, SENT, CONFIRMED] }
  
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
  
  # スコープ
  scope :initial, -> { where(status: INITIAL) }
  scope :draft, -> { where(status: DRAFT) }
  scope :sent, -> { where(status: SENT) }
  scope :confirmed, -> { where(status: CONFIRMED) }
  
  # ステータス名を取得
  def status_name
    case status
    when INITIAL then 'initial'
    when DRAFT then 'draft'
    when SENT then 'sent'
    when CONFIRMED then 'confirmed'
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
    else '不明'
    end
  end
  
  # 対象年月の表示名を取得
  def target_month_display
    return '' if target_month.blank?
    Date.strptime(target_month, "%Y-%m").strftime("%Y年%m月")
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
  
end