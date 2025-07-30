class Invoice < ApplicationRecord
  belongs_to :user
  belongs_to :invoice_recipient

  # ステータス定数
  DRAFT = 0
  SENT = 1
  CONFIRMED = 2
  
  # ステータスのバリデーション
  validates :status, inclusion: { in: [DRAFT, SENT, CONFIRMED] }
  
  # ステータス判定メソッド
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
  scope :draft, -> { where(status: DRAFT) }
  scope :sent, -> { where(status: SENT) }
  scope :confirmed, -> { where(status: CONFIRMED) }
  
  # ステータス名を取得
  def status_name
    case status
    when DRAFT then 'draft'
    when SENT then 'sent'
    when CONFIRMED then 'confirmed'
    else 'unknown'
    end
  end
  
  # ステータス表示名を取得
  def status_display_name
    case status
    when DRAFT then '下書き'
    when SENT then '送付済み'
    when CONFIRMED then '振込確認済み'
    else '不明'
    end
  end
  
end