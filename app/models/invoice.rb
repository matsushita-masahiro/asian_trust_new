class Invoice < ApplicationRecord
  belongs_to :user
  belongs_to :invoice_recipient

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
  
end